import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/app_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  IO.Socket get socket {
    if (_socket == null || !_socket!.connected) {
      _connect();
    }
    return _socket!;
  }

  void _connect() {
    _socket = IO.io(
      AppConfig.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .build(),
    );
    _socket!.connect();

    _socket!.onConnect((_) => print('✅ Socket connecté'));
    _socket!.onDisconnect((_) => print('🔴 Socket déconnecté'));
    _socket!.onConnectError((e) => print('❌ Erreur socket: $e'));
  }

  void connect() => _connect();

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  bool get isConnected => _socket?.connected ?? false;

  // ---- Émetteurs ----

  void joinRideRoom(String rideId) {
    socket.emit('join_ride', {'rideId': rideId});
  }

  void leaveRideRoom(String rideId) {
    socket.emit('leave_ride', {'rideId': rideId});
  }

  void driverGoOnline(String driverId) {
    socket.emit('driver_online', {'driverId': driverId});
  }

  void driverGoOffline(String driverId) {
    socket.emit('driver_offline', {'driverId': driverId});
  }

  void acceptRide(String rideId, String driverId) {
    socket.emit('accept_ride', {'rideId': rideId, 'driverId': driverId});
  }

  void driverArrived(String rideId) {
    socket.emit('driver_arrived', {'rideId': rideId});
  }

  void startTrip(String rideId) {
    socket.emit('start_trip', {'rideId': rideId});
  }

  void finishTrip(String rideId, double price) {
    socket.emit('finish_trip', {'rideId': rideId, 'price': price});
  }

  void updateLocation(String rideId, double lat, double lng) {
    socket.emit('update_location', {'rideId': rideId, 'lat': lat, 'lng': lng});
  }

  void sendChatMessage(String rideId, String senderId, String message) {
    socket.emit('chat_message', {
      'rideId': rideId,
      'senderId': senderId,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ---- Écouteurs ----

  void onNewRide(Function(dynamic) callback) {
    socket.on('new_ride', callback);
  }

  void onRideStatus(String rideId, Function(dynamic) callback) {
    socket.on('ride_status_$rideId', callback);
  }

  void onDriverLocation(String rideId, Function(dynamic) callback) {
    socket.on('driver_location_$rideId', callback);
  }

  void onChatMessage(String rideId, Function(dynamic) callback) {
    socket.on('chat_$rideId', callback);
  }

  void off(String event) {
    socket.off(event);
  }
}
