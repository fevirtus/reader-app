import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bọc `connectivity_plus` để phần còn lại của app chỉ cần quan tâm
/// "đang online hay không", không cần biết loại kết nối (wifi/mobile/...).
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  bool _hasNetworkTransport(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<bool> checkIsOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _hasNetworkTransport(results);
  }

  Stream<bool> get onStatusChange {
    return _connectivity.onConnectivityChanged.map(_hasNetworkTransport);
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// True khi thiết bị có kết nối mạng (không đảm bảo API thực sự truy cập được,
/// chỉ biết có transport wifi/mobile — đủ để quyết định có nên gọi API hay không).
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.checkIsOnline();
  yield* service.onStatusChange;
});
