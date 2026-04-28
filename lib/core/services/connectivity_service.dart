import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

/// Service kiểm tra kết nối mạng
class ConnectivityService extends GetxService {
  ConnectivityService._internal();
  static final ConnectivityService shared = ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final RxList<ConnectivityResult> connectivityStatus =
      <ConnectivityResult>[ConnectivityResult.none].obs;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Khởi tạo service
  Future<void> init() async {
    connectivityStatus.value = await _connectivity.checkConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(
      (result) {
        connectivityStatus.value = result;
      },
    );
  }

  /// Kiểm tra có kết nối mạng không
  bool get isConnected {
    return !connectivityStatus.contains(ConnectivityResult.none);
  }

  /// Kiểm tra có kết nối WiFi không
  bool get isWifiConnected {
    return connectivityStatus.contains(ConnectivityResult.wifi);
  }

  /// Kiểm tra có kết nối mobile data không
  bool get isMobileConnected {
    return connectivityStatus.contains(ConnectivityResult.mobile);
  }

  /// Kiểm tra có kết nối ethernet không
  bool get isEthernetConnected {
    return connectivityStatus.contains(ConnectivityResult.ethernet);
  }

  /// Dispose
  void dispose() {
    _subscription?.cancel();
  }
}
