import 'package:signalr_pure/core.dart';
import 'package:signalr_pure/signalr_pure.dart';

class ConsoleLogger implements Logger {
  Console outputConsole;
  final LogLevel? _minimumLogLevel;

  ConsoleLogger(this._minimumLogLevel) : outputConsole = console;

  @override
  void log(LogLevel logLevel, String message) {
    if (logLevel.index >= _minimumLogLevel!.index) {
      final object =
          '[${DateTime.now().toIso8601String()}] $logLevel: $message';
      switch (logLevel) {
        case LogLevel.critical:
        case LogLevel.error:
          outputConsole.error(object);
          break;
        case LogLevel.warning:
          outputConsole.warn(object);
          break;
        case LogLevel.information:
          outputConsole.info(object);
          break;
        default:
          outputConsole.log(object);
          break;
      }
    }
  }
}
