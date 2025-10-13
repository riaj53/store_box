
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
// ADD THIS IMPORT
import 'package:path_provider/path_provider.dart';
import 'binary/binary_reader.dart';
import 'binary/binary_writer.dart';
import 'encryption.dart';
import 'type_adapter.dart';

/// A custom exception for StoreBox-specific errors.
class StoreBoxException implements Exception {
  final String message;
  StoreBoxException(this.message);
  @override
  String toString() => 'StoreBoxException: $message';
}

/// A fast and simple NoSQL database for Dart and Flutter.
class StoreBox {
  // --- Singleton Setup ---
  static final StoreBox _instance = StoreBox._internal();
  StoreBox._internal();

  // --- Instance Variables ---
  String? _path;
  static const String _defaultBoxName = 'store_box_default';
  Box<dynamic>? _defaultBox;

  final Map<int, TypeAdapter> _adapters = {};
  final Map<Type, TypeAdapter> _adaptersByType = {};
  final Map<String, Box> _openBoxesByName = {};

  // --- CORE API ---

  /// Initializes the database. Must be called once before use.
  /// A default box for simple key-value storage is prepared automatically.
  static Future<void> init([String? path]) async {
    // --- THIS IS THE CORRECTED LOGIC ---
    if (path == null) {
      // If the user doesn't provide a path, get the app's documents directory.
      final docDir = await getApplicationDocumentsDirectory();
      _instance._path = p.join(docDir.path, 'db');
    } else {
      _instance._path = path;
    }
    // --- END OF CORRECTION ---

    final dir = Directory(_instance._path!);
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }

    _instance._defaultBox = await openBox<dynamic>(_defaultBoxName);
  }

  // ... rest of the file is the same ...

  /// Registers a TypeAdapter for serializing custom objects.
  static void registerAdapter<T>(TypeAdapter<T> adapter) {
    if (_instance._adapters.containsKey(adapter.typeId)) {
      if (_instance._adapters[adapter.typeId].runtimeType == adapter.runtimeType) return;
      throw StoreBoxException(
          'Adapter with typeId ${adapter.typeId} already registered.');
    }
    _instance._adapters[adapter.typeId] = adapter;
    _instance._adaptersByType[T] = adapter;
  }

  /// Saves a value to the default storage.
  static Future<void> put(String key, dynamic value) {
    _ensureInitialized();
    return _instance._defaultBox!.put(key, value);
  }

  /// Retrieves a value from the default storage. This is synchronous.
  static T? get<T>(String key) {
    _ensureInitialized();
    return _instance._defaultBox!.get(key) as T?;
  }

  /// Deletes a value from the default storage.
  static Future<void> delete(String key) {
    _ensureInitialized();
    return _instance._defaultBox!.delete(key);
  }

  /// Clears all data from the default storage.
  static Future<void> clear() {
    _ensureInitialized();
    return _instance._defaultBox!.clear();
  }

  /// Opens a named box for organized storage.
  static Future<Box<V>> openBox<V>(String name, {List<int>? encryptionKey}) async {
    _ensurePathSet();
    if (_instance._openBoxesByName.containsKey(name)) {
      return _instance._openBoxesByName[name] as Box<V>;
    }

    EncryptionCipher? cipher;
    if (encryptionKey != null) {
      final saltFile = File(p.join(_instance._path!, '$name.salt'));
      late Uint8List salt;
      if (await saltFile.exists()) {
        salt = await saltFile.readAsBytes();
      } else {
        final random = SecureRandom.safe;
        salt = Uint8List.fromList(List<int>.generate(16, (i) => random.nextInt(256)));
        await saltFile.writeAsBytes(salt);
      }
      cipher = await EncryptionCipher.fromPassword(encryptionKey, salt);
    }

    final box = Box<V>._(
      name,
      p.join(_instance._path!, '$name.box'),
      cipher,
      _instance._adapters,
      _instance._adaptersByType,
    );
    await box._init();

    _instance._openBoxesByName[name] = box;
    return box;
  }

  /// Gets a previously opened named box synchronously.
  static Box<dynamic> box(String name) {
    final box = _instance._openBoxesByName[name];
    if (box == null) {
      throw StateError(
        "Box named '$name' not found. "
            "Did you forget to call 'StoreBox.openBox(\"$name\")' first?",
      );
    }
    return box;
  }

  static void _ensureInitialized() {
    if (_instance._defaultBox == null) {
      throw StateError(
          "StoreBox has not been initialized. Please call await StoreBox.init() in your main() function.");
    }
  }

  static void _ensurePathSet() {
    if (_instance._path == null) {
      throw StateError(
          "StoreBox has not been initialized. Please call await StoreBox.init() in your main() function.");
    }
  }
}

class Box<V> {
  final String _name;
  final String _filePath;
  final EncryptionCipher? _cipher;
  final Map<int, TypeAdapter> _adapters;
  final Map<Type, TypeAdapter> _adaptersByType;
  final Map<String, V> _data = {};

  Box._(this._name, this._filePath, this._cipher, this._adapters, this._adaptersByType);

  Future<void> _init() async {
    final file = File(_filePath);
    if (!await file.exists()) return;
    var bytes = await file.readAsBytes();
    if (bytes.isEmpty) return;
    if (_cipher != null) bytes = await _cipher!.decrypt(bytes);
    final reader = BinaryReader(bytes, _adapters);
    final decodedMap = reader.read() as Map;
    _data.addAll(decodedMap.cast<String, V>());
  }

  V? get(String key) => _data[key];

  Future<void> put(String key, V value) async {
    _data[key] = value;
    await _flush();
  }

  Future<void> delete(String key) async {
    _data.remove(key);
    await _flush();
  }

  Future<void> clear() async {
    _data.clear();
    await _flush();
  }

  V? operator [](String key) => get(key);
  void operator []=(String key, V value) => put(key, value);

  Map<String, V> getAll() {
    return Map.from(_data);
  }

  Future<void> _flush() async {
    final writer = BinaryWriter(_adaptersByType);
    writer.write(_data);
    var bytes = writer.toBytes();
    if (_cipher != null) bytes = await _cipher!.encrypt(bytes);
    final file = File(_filePath);
    await file.writeAsBytes(bytes, flush: true);
  }
}
