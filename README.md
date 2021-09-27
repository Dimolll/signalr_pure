## SignalR Pure

SignalR Pure is a library which contains some useful tools for Signalr.

## USAGE
This is example code how to implement this library.
``` Dart
import 'package:signalr_pure/signalr_pure.dart';

void main() async {
  final builder = HubConnectionBuilder()
    ..url = 'url'
    ..logLevel = LogLevel.information
    ..reconnect = true;
  final connection = builder.build();
  connection.on('send', (args) => print(args));
  await connection.startAsync();
  await connection.sendAsync('send', ['Hello', 123]);
  final obj = await connection.invokeAsync('send', ['Hello', 'World']);
  print(obj);
}
```

## Acknowledgments

The base of the source code for this library was copied from the [cure][pub_link] package. Thanks to the author.

[pub_link]: https://github.com/yanshouwang/cure/

## Contact and bugs
Use [Issue Tracker][issue_tracker] for any questions or bug report.

[issue_tracker]: https://github.com/Dimolll/signalr_pure/issues/
