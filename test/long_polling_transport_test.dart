import 'dart:async';

import 'package:signalr_pure/signalr_pure.dart';
import 'package:signalr_pure/src/signalr/long_polling_transport.dart';
import 'package:signalr_pure/src/signalr/utils.dart';
import 'package:test/test.dart';

import 'common.dart';
import 'test_http_client.dart';
import 'utils.dart';

void main() {
  test('# shuts down polling by aborting in-progress request', () async {
    await VerifyLogger.runAsync((logger) async {
      var firstPoll = true;
      final pollCompleted = Completer<void>();
      final client = TestHttpClient().on((r, next) async {
        if (firstPoll) {
          firstPoll = false;
          return HttpResponse(200);
        } else {
          // Turn 'onabort' into a promise.
          final abort = Completer<void>();
          if (r.abortSignal!.aborted) {
            abort.complete();
          } else {
            r.abortSignal!.onabort = () => abort.complete();
          }
          // ignore: await_only_futures
          await abort;

          // Signal that the poll has completed.
          pollCompleted.complete();

          return HttpResponse(200);
        }
      }, 'GET').on((r, next) => HttpResponse(202), 'DELETE');
      final transport =
          LongPollingTransport(client, null, logger, false, true, {});

      await transport.connectAsync('http://example.com', TransferFormat.text);
      final stopFuture = transport.stopAsync();

      await pollCompleted.future;
      await stopFuture;
    });
  });
  test('# 204 server response stops polling and raises onClose', () async {
    await VerifyLogger.runAsync((logger) async {
      var firstPoll = true;
      final client = TestHttpClient().on((r, next) async {
        if (firstPoll) {
          firstPoll = false;
          return HttpResponse(200);
        } else {
          // A 204 response will stop the long polling transport
          return HttpResponse(204);
        }
      }, 'GET');
      final transport =
          LongPollingTransport(client, null, logger, false, true, {});

      final stopFuture = makeClosedFuture(transport);

      await transport.connectAsync('http://example.com', TransferFormat.text);

      // Close will be called on transport because of 204 result from polling
      await stopFuture;
    });
  });
  test('# sends DELETE on stop after polling has finished', () async {
    await VerifyLogger.runAsync((logger) async {
      var firstPoll = true;
      var deleteSent = false;
      final pollingCompleter = Completer<void>();
      final deleteSyncPoint = SyncPoint();
      final httpClient = TestHttpClient().on((r, next) async {
        if (firstPoll) {
          firstPoll = false;
          return HttpResponse(200);
        } else {
          await pollingCompleter.future;
          return HttpResponse(204);
        }
      }, 'GET').on((r, next) async {
        deleteSent = true;
        await deleteSyncPoint.waitToContinueAsync();
        return HttpResponse(202);
      }, 'DELETE');

      final transport =
          LongPollingTransport(httpClient, null, logger, false, true, {});

      await transport.connectAsync('http://tempuri.org', TransferFormat.text);

      // Begin stopping transport
      final stopFuture = transport.stopAsync();

      // Delete will not be sent until polling is finished
      expect(deleteSent, false);

      // Allow polling to complete
      pollingCompleter.complete();

      // Wait for delete to be called
      await deleteSyncPoint.waitForSyncPointAsync();

      expect(deleteSent, true);

      deleteSyncPoint.$continue();

      // Wait for stop to complete
      await stopFuture;
    });
  });
  test('# user agent header set on sends and polls', () async {
    await VerifyLogger.runAsync((logger) async {
      var firstPoll = true;
      String? firstPollUserAgent = '';
      String? secondPollUserAgent = '';
      String? deleteUserAgent = '';
      final pollingCompleter = Completer<void>();
      final httpClient = TestHttpClient().on((r, next) async {
        if (firstPoll) {
          firstPoll = false;
          firstPollUserAgent = r.headers!['User-Agent'];
          return HttpResponse(200);
        } else {
          secondPollUserAgent = r.headers!['User-Agent'];
          await pollingCompleter.future;
          return HttpResponse(204);
        }
      }, 'GET').on((r, next) async {
        deleteUserAgent = r.headers!['User-Agent'];
        return HttpResponse(202);
      }, 'DELETE');

      final transport =
          LongPollingTransport(httpClient, null, logger, false, true, {});

      await transport.connectAsync('http://tempuri.org', TransferFormat.text);

      // Begin stopping transport
      final stopFuture = transport.stopAsync();

      // Allow polling to complete
      pollingCompleter.complete();

      // Wait for stop to complete
      await stopFuture;

      final userAgent = getUserAgentHeader();
      expect(firstPollUserAgent, userAgent.value);
      expect(deleteUserAgent, userAgent.value);
      expect(secondPollUserAgent, userAgent.value);
    });
  });
  test('# overwrites library headers with user headers', () async {
    await VerifyLogger.runAsync((logger) async {
      final headers = {'User-Agent': 'Custom Agent', 'X-HEADER': 'VALUE'};
      var firstPoll = true;
      String? firstPollUserAgent = '';
      String? firstUserHeader = '';
      String? secondPollUserAgent = '';
      String? secondUserHeader = '';
      String? deleteUserAgent = '';
      String? deleteUserHeader = '';
      final pollingCompleter = Completer<void>();
      final httpClient = TestHttpClient().on((r, next) async {
        expect(r.content, '{"message": "hello"}');
        expect(r.headers, headers);
        expect(r.method, 'POST');
        expect(r.url, 'http://tempuri.org');
      }, 'POST').on((r, next) async {
        if (firstPoll) {
          firstPoll = false;
          firstPollUserAgent = r.headers!['User-Agent'];
          firstUserHeader = r.headers!['X-HEADER'];
          return HttpResponse(200);
        } else {
          secondPollUserAgent = r.headers!['User-Agent'];
          secondUserHeader = r.headers!['X-HEADER'];
          await pollingCompleter.future;
          return HttpResponse(204);
        }
      }, 'GET').on((r, next) async {
        deleteUserAgent = r.headers!['User-Agent'];
        deleteUserHeader = r.headers!['X-HEADER'];
        return HttpResponse(202);
      }, 'DELETE');

      final transport =
          LongPollingTransport(httpClient, null, logger, false, true, headers);

      await transport.connectAsync('http://tempuri.org', TransferFormat.text);

      final data = '{"message": "hello"}';
      await transport.sendAsync(data);

      // Begin stopping transport
      final stopFuture = transport.stopAsync();

      // Allow polling to complete
      pollingCompleter.complete();

      // Wait for stop to complete
      await stopFuture;

      expect(firstPollUserAgent, 'Custom Agent');
      expect(deleteUserAgent, 'Custom Agent');
      expect(secondPollUserAgent, 'Custom Agent');
      expect(firstUserHeader, 'VALUE');
      expect(secondUserHeader, 'VALUE');
      expect(deleteUserHeader, 'VALUE');
    });
  });
}

Future<void> makeClosedFuture(LongPollingTransport transport) {
  final closed = Completer<void>();
  transport.onclose = (error) {
    if (error != null) {
      closed.completeError(error);
    } else {
      closed.complete();
    }
  };
  return closed.future;
}
