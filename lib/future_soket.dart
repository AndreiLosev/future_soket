import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class FutureSoket {
  Socket? _socket;
  StreamSubscription<int>? _subscription;
  final _readQueue = <int>[];
  int _readId = 0;
  Duration? _timeout;

  Future<void> connect(dynamic host, int port, [Duration? timeout]) async {
    _socket = await Socket.connect(host, port, timeout: timeout);
    _subscription = _socket
        ?.asyncExpand((bytes) => Stream.fromIterable(bytes))
        .listen((_) {},
            onError: (_) async => await disconnect(),
            onDone: () async => await disconnect());
    _subscription?.pause();
  }

  FutureSoket();

  FutureSoket.fromSoket(this._socket) {
    _subscription = _socket
        ?.asyncExpand((bytes) => Stream.fromIterable(bytes))
        .listen((_) {},
            onError: (_) async => await disconnect(),
            onDone: () async => await disconnect());
    _subscription?.pause();
  }

  bool isConnected() => _socket is Socket;

  Future<Uint8List> read(int len) async {
    final id = await _waitYourTurn();
    final result = Completer<Uint8List>();
    final bytes = Uint8List(len);
    int i = 0;
    final timeout = Timer(_getTimeout(), () {
      _subscription?.pause();
      result.completeError(
          TimeoutException("read soket timeout: ${_getTimeout()}"));
    });
    _subscription?.onData((b) {
      bytes[i] = b;
      i += 1;

      if (i == len) {
        result.complete(bytes);
        _subscription?.pause();
      }
    });

    _subscription?.resume();

    final out = await result.future;
    timeout.cancel();
    _readQueue.remove(id);
    return out;
  }

  void write(Uint8List buf) {
    if (!isConnected()) {
      throw SocketException.closed();
    }

    _socket!.add(buf);
  }

  Future<void> disconnect() async {
    _subscription?.cancel();
    _subscription = null;
    await _socket?.flush();
    _socket?.close();
    _socket?.destroy();
    _socket = null;
  }

  Future<int> _waitYourTurn() async {
    final id = _nexIndex();
    _readQueue.add(id);
    while (id != _readQueue.first) {
      print([id, _readQueue]);
      await Future.delayed(const Duration(milliseconds: 10));
    }

    return id;
  }

  int _nexIndex() {
    _readId += 1;
    if (_readId > 0xffff) {
      return 1;
    }
    return _readId;
  }

  Duration _getTimeout() {
    return _timeout ?? const Duration(seconds: 10);
  }
}
