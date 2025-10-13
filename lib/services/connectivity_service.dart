import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_service.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  
  bool _isOnline = false;
  Timer? _connectionTimer;

  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    // Start listening to connectivity changes
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    
    // Check initial connectivity
    await _checkInitialConnectivity();
    
    // Start periodic connection checks
    _startPeriodicCheck();
  }

  Future<void> _checkInitialConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    await _onConnectivityChanged(connectivityResult);
  }

  Future<void> _onConnectivityChanged(ConnectivityResult result) async {
    final hasConnection = result != ConnectivityResult.none;
    
    if (hasConnection) {
      // Test actual internet connectivity by pinging the API
      await _testInternetConnection();
    } else {
      _updateConnectionStatus(false);
    }
  }

  Future<void> _testInternetConnection() async {
    try {
      // Try to reach the API backend
      final isApiReachable = await ApiService.testConnection();
      _updateConnectionStatus(isApiReachable);
    } catch (e) {
      // If API is not reachable, check general internet connectivity
      final hasInternet = await _testGeneralInternet();
      _updateConnectionStatus(hasInternet);
    }
  }

  Future<bool> _testGeneralInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void _updateConnectionStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _connectionController.add(_isOnline);
    }
  }

  void _startPeriodicCheck() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_isOnline) {
        // If we think we're online, verify it
        await _testInternetConnection();
      } else {
        // If we think we're offline, check if we're back online
        final connectivityResult = await _connectivity.checkConnectivity();
        await _onConnectivityChanged(connectivityResult);
      }
    });
  }

  // Manual connection test
  Future<bool> testConnection() async {
    try {
      return await ApiService.testConnection();
    } catch (e) {
      return false;
    }
  }

  // Get current connection type
  Future<String> getConnectionType() async {
    final result = await _connectivity.checkConnectivity();
    
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.none:
        return 'No Connection';
      default:
        return 'Unknown';
    }
  }

  // Check if we can reach the specific API backend
  Future<bool> canReachBackend() async {
    try {
      return await ApiService.testConnection();
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _connectionTimer?.cancel();
    _connectionController.close();
  }
}
