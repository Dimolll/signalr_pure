import 'package:signalr_pure/sse.dart';
import 'package:signalr_pure/ws.dart';

typedef WebSocketConstructor = WebSocket Function(
    String url, List<String>? protocols, Map<String, String>? headers);

typedef EventSourceConstructor = EventSource Function(
    String url, Map<String, String>? headers, bool? withCredentials);
