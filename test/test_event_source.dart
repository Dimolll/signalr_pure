import 'dart:async';

import 'package:signalr_pure/sse.dart';

class TestEventSource implements EventSource {
  @override
  void Function(String event, String? data)? ondata;
  @override
  void Function(Object? error)? onerror;
  Completer<void> openSet;
  void Function()? _onopen;
  @override
  void Function()? get onopen => _onopen;
  @override
  set onopen(void Function()? value) {
    _onopen = value;
    openSet.complete();
  }

  @override
  int readyState;
  @override
  String url;
  bool withCredentials;
  Map<String, String>? headers;
  bool closed;

  static Completer<void>? eventSourceSet;
  static late TestEventSource eventSource;

  TestEventSource(this.url, {this.headers})
      : readyState = 0,
        withCredentials = false,
        openSet = Completer(),
        closed = false {
    eventSource = this;
    TestEventSource.eventSourceSet?.complete();
  }

  @override
  void close() {
    closed = true;
  }
}
