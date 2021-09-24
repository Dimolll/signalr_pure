import 'event_source_stub.dart'
    if (dart.library.html) 'event_source_chromium.dart'
    if (dart.library.io) 'event_source_dartium.dart';

/// EventSource
abstract class EventSource {
  /// CONNECTING = 0
  static const int connecting = 0;

  /// OPEN = 1
  static const int open = 1;

  /// CLOSED = 2
  static const int closed = 2;

  /// url
  String get url;

  /// readyState
  int get readyState;

  /// onopen
  void Function()? onopen;

  /// onerror
  void Function(Object? error)? onerror;

  /// ondata
  void Function(String event, String? data)? ondata;

  /// Close the EventSource.
  void close();

  /// Connect to the [url].
  factory EventSource.connect(String url,
          {Map<String, String>? headers, bool? withCredentials}) =>
      connectEventSource(url);
}
