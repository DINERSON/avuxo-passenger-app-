import 'package:socket_io_client/socket_io_client.dart' as io;

class PassengerSocketService {
  PassengerSocketService({
    required this.baseUrl,
  });

  final String baseUrl;

  io.Socket? _socket;
  String? _currentRideId;
  String? _passengerId;

  bool get connected => _socket?.connected == true;
  String? get currentRideId => _currentRideId;

  String? _cleanRideId(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      final id = value['rideId'] ??
          value['id'] ??
          value['_id'] ??
          value['ride_id'];

      if (id == null) return null;

      final clean = id.toString().trim();

      if (clean.isEmpty || clean.toLowerCase() == 'null') {
        return null;
      }

      return clean;
    }

    final clean = value.toString().trim();

    if (clean.isEmpty || clean.toLowerCase() == 'null') {
      return null;
    }

    return clean;
  }

  String? _extractRideIdFromData(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      final directId = _cleanRideId(
        data['rideId'] ??
            data['id'] ??
            data['_id'] ??
            data['ride_id'],
      );

      if (directId != null) return directId;

      final ride = data['ride'];
      if (ride is Map) return _cleanRideId(ride);

      final payload = data['data'];
      if (payload is Map) return _cleanRideId(payload);

      final driver = data['driver'];
      if (driver is Map) return _cleanRideId(driver);

      final chat = data['chat'];
      if (chat is Map) return _cleanRideId(chat);
    }

    return null;
  }

  bool _isSameRide(dynamic data) {
    if (_currentRideId == null || _currentRideId!.isEmpty) {
      return true;
    }

    final dataRideId = _extractRideIdFromData(data);

    if (dataRideId == null) {
      return true;
    }

    return dataRideId == _currentRideId;
  }

  bool _isPassengerRide(dynamic data) {
    final passengerId = _passengerId?.trim();

    if (passengerId == null || passengerId.isEmpty) {
      return true;
    }

    if (data is! Map) {
      return true;
    }

    final ride = data['ride'] is Map ? data['ride'] as Map : data;
    final passenger = ride['passenger'];

    final ridePassengerId = ride['passengerId'] ??
        ride['userId'] ??
        (passenger is Map
            ? passenger['uid'] ??
                passenger['id'] ??
                passenger['phone'] ??
                passenger['email']
            : null);

    if (ridePassengerId == null) {
      return true;
    }

    return ridePassengerId.toString().trim() == passengerId;
  }

  void connect({
    required void Function(dynamic data) onRideData,
    required void Function(dynamic data) onDriverLocation,
    required void Function(dynamic data) onChatUpdated,
    String passengerId = 'passenger-avuxo',
  }) {
    _passengerId = passengerId.trim();

    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();

    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableForceNew()
          .enableReconnection()
          .setReconnectionAttempts(999)
          .setReconnectionDelay(800)
          .enableAutoConnect()
          .build(),
    );

    void joinPassengerRooms() {
      _socket?.emit('passenger:join', {
        'passengerId': passengerId,
      });

      _socket?.emit('join:passenger', {
        'passengerId': passengerId,
      });

      if (_currentRideId != null && _currentRideId!.isNotEmpty) {
        joinRide(_currentRideId);
        requestCurrentRide(rideId: _currentRideId);
        requestChat(rideId: _currentRideId);
      }
    }

    _socket?.onConnect((_) {
      joinPassengerRooms();
    });

    _socket?.onDisconnect((_) {});

    _socket?.on('reconnect', (_) {
      joinPassengerRooms();
    });

    _socket?.onConnectError((_) {});
    _socket?.onError((_) {});
    _socket?.on('server:ready', (_) {});

    void handleRide(dynamic data) {
      final rideId = _extractRideIdFromData(data);

      if (!_isPassengerRide(data)) return;

      if (_currentRideId != null &&
          _currentRideId!.isNotEmpty &&
          rideId != null &&
          rideId.isNotEmpty &&
          rideId != _currentRideId) {
        joinRide(rideId);
      }

      if (!_isSameRide(data)) return;

      onRideData(data);
    }

    void handleLocation(dynamic data) {
      if (!_isSameRide(data)) return;
      onDriverLocation(data);
    }

    void handleChat(dynamic data) {
      if (!_isSameRide(data)) return;
      onChatUpdated(data);
    }

    _socket?.on('ride:current', handleRide);
    _socket?.on('ride:updated', handleRide);
    _socket?.on('ride:update', handleRide);
    _socket?.on('ride:requested', handleRide);
    _socket?.on('ride:declined', handleRide);
    _socket?.on('ride:accepted', handleRide);
    _socket?.on('ride:arriving', handleRide);
    _socket?.on('ride:arrived', handleRide);
    _socket?.on('ride:started', handleRide);
    _socket?.on('ride:finished', handleRide);
    _socket?.on('ride:cancelled', handleRide);
    _socket?.on('ride:canceled', handleRide);
    _socket?.on('ride:cleared', handleRide);

    _socket?.on('driver:location', handleLocation);
    _socket?.on('ride:tracking', handleLocation);
    _socket?.on('driver:tracking', handleLocation);

    _socket?.on('chat:updated', handleChat);
    _socket?.on('chat:update', handleChat);
    _socket?.on('chat:message', handleChat);

    _socket?.connect();
  }

  void joinRide(dynamic rideId) {
    final id = _cleanRideId(rideId);

    if (id == null) return;

    _currentRideId = id;

    _socket?.emit('join:ride', {
      'rideId': id,
    });

    _socket?.emit('ride:join', {
      'rideId': id,
    });
  }

  void leaveRide(dynamic rideId) {
    final id = _cleanRideId(rideId);

    if (id == null) return;

    _socket?.emit('leave:ride', {
      'rideId': id,
    });

    _socket?.emit('ride:leave', {
      'rideId': id,
    });

    if (_currentRideId == id) {
      _currentRideId = null;
    }
  }

  void clearRide() {
    _currentRideId = null;
  }

  void requestCurrentRide({
    dynamic rideId,
  }) {
    final id = _cleanRideId(rideId) ?? _currentRideId;

    if (id != null && id.isNotEmpty) {
      _socket?.emit('ride:get-current', {
        'rideId': id,
      });

      _socket?.emit('ride:current:get', {
        'rideId': id,
      });

      return;
    }

    _socket?.emit('ride:get-current');
    _socket?.emit('ride:current:get');
  }

  void requestChat({
    dynamic rideId,
  }) {
    final id = _cleanRideId(rideId) ?? _currentRideId;

    if (id == null || id.isEmpty) return;

    _socket?.emit('chat:get', {
      'rideId': id,
    });

    _socket?.emit('chat:current', {
      'rideId': id,
    });
  }

  void sendChatMessage(
    String text, {
    dynamic rideId,
  }) {
    final clean = text.trim();

    if (clean.isEmpty) return;

    final id = _cleanRideId(rideId) ?? _currentRideId;

    if (id == null || id.isEmpty) {
      return;
    }

    _socket?.emit(
      'chat:send',
      {
        'rideId': id,
        'sender': 'passenger',
        'from': 'passenger',
        'role': 'passenger',
        'message': clean,
        'text': clean,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }

  void dispose() {
    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentRideId = null;
    _passengerId = null;
  }
}
