// ignore_for_file: overridden_fields

import 'package:signalr_pure/signalr_pure.dart';

class TestTransport extends Transport {
  @override
  void Function(Object? error)? onclose;
  @override
  void Function(Object data)? onreceive;

  @override
  Future<void> connectAsync(String? url, TransferFormat transferFormat) {
    return Future.value();
  }

  @override
  Future<void> sendAsync(data) {
    return Future.value();
  }

  @override
  Future<void> stopAsync() {
    return Future.value();
  }
}
