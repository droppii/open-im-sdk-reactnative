package com.openimsdkrn.listener;

import com.facebook.react.bridge.ReactApplicationContext;
import com.openimsdkrn.utils.Emitter;

import open_im_sdk_callback.OnNetworkLogListener;

public class NetworkLogListener extends Emitter implements OnNetworkLogListener {
  private final ReactApplicationContext ctx;

  public NetworkLogListener(ReactApplicationContext ctx) {
    this.ctx = ctx;
  }

  // Forward the raw JSON string; JS parses it, avoiding a second conversion here.
  // Called from a Go thread: it can fire before the JS instance is ready or after
  // a reload tore it down, and a Java exception here would cross into gomobile.
  @Override
  public void onNetworkLog(String s) {
    if (!ctx.hasActiveReactInstance()) return;
    try {
      send(ctx, "onNetworkLog", s);
    } catch (Exception ignored) {
      // Debug-only event: dropping it is always safe.
    }
  }
}
