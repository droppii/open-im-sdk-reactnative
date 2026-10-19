package com.openimsdkrn.crash;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.Log;

import java.io.File;
import java.util.concurrent.atomic.AtomicBoolean;

import open_im_sdk.Open_im_sdk;
import open_im_sdk_callback.OnCrashReportListener;

/** Receives panic reports from the Go core and forwards them to Bugsnag when the app ships it. */
public final class CoreCrashReporter implements OnCrashReportListener {
  private static final String TAG = "OpenIMCore";
  /** App manifest meta-data that allows the crash trigger outside debug builds, e.g. on staging. */
  private static final String TRIGGER_META_KEY = "com.openimsdkrn.ENABLE_CORE_CRASH_TRIGGER";
  private static final AtomicBoolean installed = new AtomicBoolean(false);

  private CoreCrashReporter() {}

  /**
   * Starts receiving core panic reports and records Go fatal errors under the app files dir; a fatal
   * error left by the previous run is reported right away. Safe to call more than once.
   */
  public static void install(Context context) {
    if (!installed.compareAndSet(false, true)) {
      return;
    }
    try {
      File dir = new File(context.getApplicationContext().getFilesDir(), "openim_crash");
      Open_im_sdk.setCrashReportListener(new CoreCrashReporter());
      if (!Open_im_sdk.enableCrashReport(dir.getAbsolutePath())) {
        Log.w(TAG, "enableCrashReport failed for " + dir);
      }
    } catch (Throwable t) {
      Log.e(TAG, "installing the core crash reporter failed", t);
    }
  }

  /** The crash trigger runs in debuggable builds, or when the app opts in through its manifest. */
  public static boolean isTriggerAllowed(Context context) {
    if ((context.getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
      return true;
    }
    try {
      Bundle metaData = context.getPackageManager()
        .getApplicationInfo(context.getPackageName(), PackageManager.GET_META_DATA)
        .metaData;
      Object value = metaData == null ? null : metaData.get(TRIGGER_META_KEY);
      return Boolean.TRUE.equals(value) || "true".equalsIgnoreCase(String.valueOf(value));
    } catch (Exception e) {
      return false;
    }
  }

  // Called on a Go thread: gomobile leaves a Java exception pending on that thread, so nothing may escape.
  @Override
  public boolean onCrashReport(String json) {
    try {
      CoreCrashReport report = CoreCrashReport.parse(json);
      Log.e(TAG, "core " + report.kind + " in " + report.where + ": " + report.message + "\n" + report.stack);
      boolean sent;
      try {
        sent = BugsnagCoreReporter.notify(report);
      } catch (LinkageError e) {
        sent = false;
      }
      if (!sent) {
        Log.w(TAG, "Bugsnag is not available; the core crash report was only logged");
      }
      return sent;
    } catch (Throwable t) {
      Log.e(TAG, "handling a core crash report failed", t);
      return false;
    }
  }
}
