import 'dart:convert';
import 'dart:typed_data';

import '../type_adapter.dart';

/// A writer that converts Dart objects into a binary format.
class BinaryWriter {
  final _byteData = BytesBuilder();
  final Map<Type, TypeAdapter> _adaptersByType;

  /// Creates a new BinaryWriter.
  BinaryWriter(this._adaptersByType);

  /// Writes a Dart object to the buffer.
  void write(dynamic value) {
    if (value == null) {
      _byteData.addByte(0); // Null
    } else if (value is int) {
      _byteData.addByte(1); // int
      _byteData.add((ByteData(8)..setInt64(0, value, Endian.little))
          .buffer
          .asUint8List());
    } else if (value is double) {
      _byteData.addByte(2); // double
      _byteData.add((ByteData(8)..setFloat64(0, value, Endian.little))
          .buffer
          .asUint8List());
    } else if (value is bool) {
      _byteData.addByte(3); // bool
      _byteData.addByte(value ? 1 : 0);
    } else if (value is String) {
      _byteData.addByte(4); // String
      final bytes = utf8.encode(value);
      writeInt(bytes.length);
      _byteData.add(bytes);
    } else if (value is List) {
      _byteData.addByte(5); // List
      writeInt(value.length);
      for (var item in value) {
        write(item);
      }
    } else if (value is Map) {
      _byteData.addByte(6); // Map
      writeInt(value.length);
      for (var entry in value.entries) {
        write(entry.key); // Write the key
        write(entry.value); // Write the value
      }
    } else {
      final adapter = _findAdapterForValue(value);
      if (adapter != null) {
        _byteData.addByte(100); // Custom Object
        writeInt(adapter.typeId);
        adapter.write(this, value);
      } else {
        throw ArgumentError('Cannot write, unknown type: ${value.runtimeType}');
      }
    }
  }

  /// Writes an integer value.
  void writeInt(int value) => write(value);

  /// Returns the bytes that have been written.
  Uint8List toBytes() => _byteData.toBytes();

  /// Finds the adapter for a given value by its runtime type.
  TypeAdapter? _findAdapterForValue(dynamic value) {
    return _adaptersByType[value.runtimeType];
  }
}

