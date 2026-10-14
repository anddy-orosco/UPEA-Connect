import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Detecta si la app tiene conexión REAL con el backend (no solo WiFi).
/// Vive en lib/services/connectivity_service.dart
///
/// Cada pocos segundos consulta /api/health, y además los servicios avisan
/// al instante cuando una petición falla por red ([reportFailure]) o tiene
/// éxito ([reportSuccess]).
class ConnectivityService extends ChangeNotifier {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  bool _isOnline = true;
  bool _justReconnected = false;
  bool _checking = false;
  int _timeoutStreak = 0;
  Timer? _timer;
  Timer? _reconnectedTimer;

  /// Mensaje estándar cuando se intenta guardar algo sin internet.
  static const String offlineWriteMessage =
      'Sin conexión: no se pudo completar. Inténtalo cuando vuelva internet.';

  /// true si hay conexión con el backend.
  bool get isOnline => _isOnline;

  /// true durante unos segundos después de recuperar la conexión.
  bool get justReconnected => _justReconnected;

  /// Empieza a vigilar la conexión (se llama una vez, desde main()).
  void start() {
    if (_timer != null) return;
    checkNow();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => checkNow());
  }

  /// ¿Esta excepción es un problema de red (sin internet, DNS, timeout)?
  static bool isNetworkError(Object e) {
    if (e is TimeoutException || e is http.ClientException) return true;
    final text = e.toString();
    return text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('Connection refused') ||
        text.contains('Network is unreachable');
  }

  /// Una petición real salió bien: hay conexión.
  void reportSuccess() => _setOnline(true);

  /// Una petición real falló por red: se marca sin conexión de inmediato.
  void reportFailure() => _setOnline(false);

  Future<void> checkNow() async {
    if (_checking) return;
    _checking = true;
    try {
      final res = await http
          .get(Uri.parse('${ApiService.baseUrl}/health'))
          .timeout(const Duration(seconds: 8));
      _timeoutStreak = 0;
      _setOnline(res.statusCode < 500);
    } on TimeoutException {
      // Un timeout aislado puede ser solo un backend lento: se exigen dos seguidos.
      _timeoutStreak++;
      if (_timeoutStreak >= 2) _setOnline(false);
    } catch (_) {
      _timeoutStreak = 0;
      _setOnline(false);
    } finally {
      _checking = false;
    }
  }

  void _setOnline(bool value) {
    if (value == _isOnline) return;

    final volvio = value && !_isOnline;
    _isOnline = value;

    if (volvio) {
      _justReconnected = true;
      _reconnectedTimer?.cancel();
      _reconnectedTimer = Timer(const Duration(seconds: 3), () {
        _justReconnected = false;
        notifyListeners();
      });
    } else {
      _justReconnected = false;
      _reconnectedTimer?.cancel();
    }

    notifyListeners();
  }
}
