/// Service de vérification de la connexion Internet
///
/// Utilise internet_connection_checker_plus pour surveiller l'état de la connexion
/// et notifier l'application en temps réel.

import 'dart:async';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final InternetConnection _internetConnection = InternetConnection();
  
  StreamController<bool>? _connectionStatusController;
  StreamSubscription<InternetStatus>? _subscription;

  /// Stream qui émet true quand connecté, false quand déconnecté
  Stream<bool> get connectionStatus {
    _connectionStatusController ??= StreamController<bool>.broadcast();
    return _connectionStatusController!.stream;
  }

  /// Démarre l'écoute de l'état de connexion
  void startMonitoring() {
    _subscription ??= _internetConnection.onStatusChange.listen(
      (InternetStatus status) {
        final isConnected = status == InternetStatus.connected;
        _connectionStatusController?.add(isConnected);
      },
    );
  }

  /// Arrête l'écoute de l'état de connexion
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Vérifie l'état actuel de la connexion (une seule fois)
  Future<bool> checkConnection() async {
    final status = await _internetConnection.internetStatus;
    return status == InternetStatus.connected;
  }

  /// Dispose les ressources
  void dispose() {
    stopMonitoring();
    _connectionStatusController?.close();
    _connectionStatusController = null;
  }
}
