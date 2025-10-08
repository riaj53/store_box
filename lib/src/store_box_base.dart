import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'binary/binary_reader.dart';
import 'binary/binary_writer.dart';
import 'encryption.dart';
import 'type_adapter.dart';

/// A custom exception for StoreBox-specific errors.
class StoreBoxException implements Exception {
  /// The message describing the error.
  final String message;
  /// Creates a new StoreBoxException.
  StoreBoxException(this.message);
  @override
  String toString() => 'StoreBoxException: $message';
}

/// The main class for managing all database boxes.
class StoreBox {
  static final StoreBox _instance = StoreBox._internal();
  /// The factory constructor to access the singleton instance.
  factory StoreBox() => _instance;
  StoreBox._internal();

  String? _path;
  final Map<int, TypeAdapter> _adapters = {};
  final Map<Type, TypeAdapter> _adaptersByType = {};
  final Map<String, Box> _openBoxes = {};

  /// Initializes the database at a specific directory.
  Future<void> init(String path) async {
    _path = path;
    final dir = Directory(path);
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }
  }

  /// Registers a TypeAdapter for serializing custom objects.
  void registerAdapter<T>(TypeAdapter<T> adapter) {
    if (_adapters.containsKey(adapter.typeId)) {
      throw StoreBoxException(
          'Adapter with typeId ${adapter.typeId} already registered.');
    }
    _adapters[adapter.typeId] = adapter;
    _adaptersByType[T] = adapter;
  }

  /// Opens a box.
  Future<Box<V>> openBox<V>(String name, {List<int>? encryptionKey}) async {
    if (_path == null) {
      throw StateError(
          "StoreBox has not been initialized. Please call init() first.");
    }
    if (_openBoxes.containsKey(name)) {
      return _openBoxes[name] as Box<V>;
    }

    EncryptionCipher? cipher;
    if (encryptionKey != null) {
      final saltFile = File(p.join(_path!, '$name.salt'));
      late Uint8List salt;
      if (await saltFile.exists()) {
        salt = await saltFile.readAsBytes();
      } else {
        // CORRECTED: This is the robust way to generate a list of secure
        // random bytes, avoiding the method resolution error.
        final random = SecureRandom.safe;
        salt = Uint8List.fromList(
            List<int>.generate(16, (i) => random.nextInt(256)));
        await saltFile.writeAsBytes(salt);
      }
      cipher = await EncryptionCipher.fromPassword(encryptionKey, salt);
    }

    final box = Box<V>._(
      name,
      p.join(_path!, '$name.box'),
      cipher,
      _adapters,
      _adaptersByType,
    );
    await box._init();
    _openBoxes[name] = box;
    return box;
  }
}

/// A persistent key-value store.
class Box<V> {
  final String _name;
  final String _filePath;
  final EncryptionCipher? _cipher;
  final Map<int, TypeAdapter> _adapters;
  final Map<Type, TypeAdapter> _adaptersByType;
  final Map<String, V> _data = {};

  Box._(this._name, this._filePath, this._cipher, this._adapters,
      this._adaptersByType);

  Future<void> _init() async {
    final file = File(_filePath);
    if (!await file.exists()) return;

    var bytes = await file.readAsBytes();
    if (bytes.isEmpty) return;

    if (_cipher != null) {
      bytes = await _cipher!.decrypt(bytes);
    }

    final reader = BinaryReader(bytes, _adapters);
    final decodedMap = reader.read() as Map;

    _data.addAll(decodedMap.cast<String, V>());
  }

  /// Retrieves a value from the box.
  V? get(String key) => _data[key];

  /// Saves a key-value pair to the box.
  Future<void> put(String key, V value) async {
    _data[key] = value;
    await _flush();
  }

  /// Removes a key-value pair from the box.
  Future<void> delete(String key) async {
    _data.remove(key);
    await _flush();
  }

  Future<void> _flush() async {
    final writer = BinaryWriter(_adaptersByType);
    writer.write(_data);
    var bytes = writer.toBytes();

    if (_cipher != null) {
      bytes = await _cipher!.encrypt(bytes);
    }

    final file = File(_filePath);
    await file.writeAsBytes(bytes, flush: true);
  }
}

