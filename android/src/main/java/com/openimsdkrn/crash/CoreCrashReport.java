package com.openimsdkrn.crash;

import org.json.JSONArray;
import org.json.JSONObject;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/** A panic report produced by the Go core (pkg/crash.Report). */
final class CoreCrashReport {
  static final class Frame {
    final String function;
    final String file;
    final int line;
    final boolean inProject;

    Frame(String function, String file, int line, boolean inProject) {
      this.function = function;
      this.file = file;
      this.line = line;
      this.inProject = inProject;
    }
  }

  String kind = "";
  String message = "";
  String where = "";
  String operationID = "";
  String coreVersion = "";
  String goVersion = "";
  long time;
  int suppressed;
  String stack = "";
  String trail = "";
  final List<Frame> frames = new ArrayList<>();

  static CoreCrashReport parse(String json) throws Exception {
    JSONObject o = new JSONObject(json);
    CoreCrashReport r = new CoreCrashReport();
    r.kind = o.optString("kind");
    r.message = o.optString("message");
    r.where = o.optString("where");
    r.operationID = o.optString("operationID");
    r.coreVersion = o.optString("coreVersion");
    r.goVersion = o.optString("goVersion");
    r.time = o.optLong("time");
    r.suppressed = o.optInt("suppressed");
    r.stack = o.optString("stack");
    JSONArray frames = o.optJSONArray("frames");
    for (int i = 0; frames != null && i < frames.length(); i++) {
      JSONObject f = frames.getJSONObject(i);
      r.frames.add(new Frame(f.optString("function"), f.optString("file"), f.optInt("line"), f.optBoolean("inProject")));
    }
    r.trail = formatTrail(o.optJSONArray("trail"));
    return r;
  }

  boolean isFatal() {
    return "fatal".equals(kind);
  }

  String errorClass() {
    return isFatal() ? "GoFatalError" : "GoPanic";
  }

  String groupingHash() {
    for (Frame f : frames) {
      if (f.inProject) {
        return errorClass() + ":" + f.function;
      }
    }
    return errorClass() + ":" + (frames.isEmpty() ? message : frames.get(0).function);
  }

  /** A throwable whose stack trace is the Go stack, innermost frame first. */
  Throwable toThrowable() {
    RuntimeException t = new RuntimeException(message);
    StackTraceElement[] elements = new StackTraceElement[frames.size()];
    for (int i = 0; i < frames.size(); i++) {
      Frame f = frames.get(i);
      int slash = f.function.lastIndexOf('/');
      int dot = f.function.lastIndexOf('.');
      String declaringClass = dot > slash ? f.function.substring(0, dot) : f.function;
      String method = dot > slash ? f.function.substring(dot + 1) : f.function;
      elements[i] = new StackTraceElement(declaringClass, method, f.file, f.line);
    }
    t.setStackTrace(elements);
    return t;
  }

  Map<String, Object> metadata() {
    Map<String, Object> m = new HashMap<>();
    m.put("kind", kind);
    m.put("where", where);
    m.put("operationID", operationID);
    m.put("coreVersion", coreVersion);
    m.put("goVersion", goVersion);
    m.put(isFatal() ? "crashedAt" : "panickedAt", formatTime(time));
    m.put("previousRun", isFatal());
    m.put("suppressedRepeats", suppressed);
    putChunked(m, "trail", trail);
    putChunked(m, "goStack", stack);
    return m;
  }

  // Bugsnag may cut metadata strings at 10000 chars; split instead of losing the end.
  private static void putChunked(Map<String, Object> m, String key, String value) {
    final int max = 9000;
    if (value.length() <= max) {
      m.put(key, value);
      return;
    }
    for (int start = 0, part = 1; start < value.length(); start += max, part++) {
      m.put(part == 1 ? key : key + "_" + part, value.substring(start, Math.min(value.length(), start + max)));
    }
  }

  private static String formatTrail(JSONArray trail) {
    if (trail == null) {
      return "";
    }
    StringBuilder b = new StringBuilder();
    for (int i = 0; i < trail.length(); i++) {
      JSONObject e = trail.optJSONObject(i);
      if (e == null) {
        continue;
      }
      b.append(formatTime(e.optLong("t"))).append(' ').append(e.optString("step"));
      String detail = e.optString("detail");
      if (!detail.isEmpty()) {
        b.append(' ').append(detail);
      }
      String op = e.optString("op");
      if (!op.isEmpty()) {
        b.append(" op=").append(op);
      }
      int repeat = e.optInt("repeat");
      if (repeat > 0) {
        b.append(" (repeated ").append(repeat).append("x)");
      }
      b.append('\n');
    }
    return b.toString();
  }

  private static String formatTime(long millis) {
    return new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ", Locale.US).format(new Date(millis));
  }
}
