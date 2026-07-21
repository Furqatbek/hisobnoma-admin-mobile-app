import 'dart:async';
import 'dart:io';

/// Lightweight connectivity checker — no external dependencies
class ConnectivityChecker {
  bool _isOnline = true;
  final _controller = StreamController<bool>.broadcast();

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Current connectivity status
  bool get isOnline => _isOnline;

  /// Check actual connectivity by attempting a DNS lookup
  Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      _isOnline = false;
    } on TimeoutException catch (_) {
      _isOnline = false;
    }

    _controller.add(_isOnline);
    return _isOnline;
  }

  void dispose() {
    _controller.close();
  }
}
