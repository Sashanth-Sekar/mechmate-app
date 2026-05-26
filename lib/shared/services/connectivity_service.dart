import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Singleton connectivity monitor.
///
/// Usage:
///   final cs = ConnectivityService.instance;
///   if (cs.isOnline) { ... }
///   cs.onlineStream.listen((online) => ...);
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onlineStream => _controller.stream;

  /// Call once at app startup.
  Future<void> initialize() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _update(results);
    } catch (e) {
      debugPrint('ConnectivityService init: $e');
    }

    _sub = _connectivity.onConnectivityChanged.listen(
      _update,
      onError: (e) => debugPrint('ConnectivityService stream error: $e'),
    );
  }

  void _update(List<ConnectivityResult> results) {
    final online = results.any(
      (r) => r != ConnectivityResult.none,
    );
    if (online != _isOnline) {
      _isOnline = online;
      _controller.add(online);
      debugPrint('Connectivity: ${online ? "ONLINE" : "OFFLINE"}');
    }
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
