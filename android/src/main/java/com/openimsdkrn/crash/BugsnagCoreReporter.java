package com.openimsdkrn.crash;

import com.bugsnag.android.Bugsnag;
import com.bugsnag.android.Severity;
import com.bugsnag.android.Stackframe;

import java.util.List;

/**
 * The only class that touches Bugsnag. Bugsnag is a compileOnly dependency: in apps that do not
 * ship it, loading this class fails with NoClassDefFoundError, which callers catch.
 */
final class BugsnagCoreReporter {
  private BugsnagCoreReporter() {}

  static boolean notify(final CoreCrashReport report) {
    if (!Bugsnag.isStarted()) {
      return false;
    }
    Bugsnag.notify(report.toThrowable(), event -> {
      // Metadata first: if a later step fails, the event still carries the Go stack and trail.
      event.addMetadata("openim_core", report.metadata());
      event.setContext(report.where);
      event.setGroupingHash(report.groupingHash());
      // A previous run's fatal error stays handled so the current, healthy session is not counted as crashed.
      event.setSeverity(Severity.ERROR);
      com.bugsnag.android.Error error = event.getErrors().get(0);
      error.setErrorClass(report.errorClass());
      error.setErrorMessage(report.message);
      try {
        List<Stackframe> frames = error.getStacktrace();
        for (int i = 0; i < frames.size() && i < report.frames.size(); i++) {
          frames.get(i).setInProject(report.frames.get(i).inProject);
        }
      } catch (RuntimeException ignored) {
        // inProject only improves grouping.
      }
      return true;
    });
    return true;
  }
}
