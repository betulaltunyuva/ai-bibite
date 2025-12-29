import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  /// İnternet bağlantısını kontrol et
  Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet;
    } catch (e) {
      // Sessiz mod: hata loglanmaz
      return false;
    }
  }

  /// İnternet bağlantısı gelene kadar bekle (maksimum 30 saniye)
  Future<bool> waitForConnection({int maxWaitSeconds = 30}) async {
    int waited = 0;
    while (waited < maxWaitSeconds) {
      if (await hasInternetConnection()) {
        return true;
      }
      await Future.delayed(const Duration(seconds: 1));
      waited++;
    }
    return false;
  }

  /// İnternet bağlantısı değişikliklerini dinle
  void listenToConnectivity(Function(bool) onConnectivityChanged) {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        final hasConnection = result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet;
        onConnectivityChanged(hasConnection);
      },
    );
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

