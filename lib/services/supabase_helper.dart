import 'network_service.dart';

class SupabaseHelper {
  static final SupabaseHelper _instance = SupabaseHelper._internal();
  factory SupabaseHelper() => _instance;
  SupabaseHelper._internal();

  final NetworkService _networkService = NetworkService();

  /// Supabase işlemini retry mekanizması ile çalıştır
  Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    bool silent = true,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        // İnternet bağlantısı kontrolü
        if (!await _networkService.hasInternetConnection()) {
          if (attempts < maxRetries - 1) {
            // İnternet gelene kadar bekle (maksimum 10 saniye)
            final hasConnection = await _networkService.waitForConnection(
              maxWaitSeconds: 10,
            );
            if (!hasConnection && attempts < maxRetries - 1) {
              attempts++;
              await Future.delayed(retryDelay);
              continue;
            }
          }
          
          if (!silent) {
            throw Exception('İnternet bağlantısı yok');
          }
          throw _SilentException('İnternet bağlantısı yok');
        }

        // İşlemi çalıştır
        return await operation();
      } on _SilentException {
        rethrow;
      } catch (e) {
        attempts++;
        
        // Son deneme değilse tekrar dene
        if (attempts < maxRetries) {
          await Future.delayed(retryDelay);
          continue;
        }
        
        // Sessiz mod: hata loglanmaz, ama gerçek hata mesajını koru
        if (silent) {
          // Gerçek hatayı koru, sadece loglama yapma
          throw _SilentException(e.toString());
        }
        rethrow;
      }
    }
    
    throw _SilentException('İşlem başarısız oldu');
  }

  /// Supabase query işlemini sessiz modda çalıştır
  Future<T?> executeQuerySilent<T>(Future<T> Function() query) async {
    try {
      return await executeWithRetry(
        operation: query,
        silent: true,
      );
    } on _SilentException {
      return null;
    } catch (e) {
      // Sessiz mod: hata loglanmaz
      return null;
    }
  }
}

/// Sessiz hata sınıfı (loglanmaz)
class _SilentException implements Exception {
  final String message;
  _SilentException(this.message);
  
  @override
  String toString() => message;
}

