import 'dart:convert';
import 'dart:typed_data';

import '../type_adapter.dart';

/// A reader that decodes binary data into Dart objects.
class BinaryReader {
  final ByteData _byteData;
  int _offset = 0;
  final Map<int, TypeAdapter> _adapters;

  /// Creates a new BinaryReader.
  BinaryReader(Uint8List bytes, this._adapters)
      : _byteData = ByteData.view(bytes.buffer);

  /// Reads the next Dart object from the buffer.
  dynamic read() {
    final type = _byteData.getUint8(_offset++);
    switch (type) {
      case 0: // Null
        return null;
      case 1: // int
        final value = _byteData.getInt64(_offset, Endian.little);
        _offset += 8;
        return value;
      case 2: // double
        final value = _byteData.getFloat64(_offset, Endian.little);
        _offset += 8;
        return value;
      case 3: // bool
        return _byteData.getUint8(_offset++) == 1;
      case 4: // String
        final len = read() as int;
        final bytes = _byteData.buffer.asUint8List(_offset, len);
        _offset += len;
        return utf8.decode(bytes);
      case 5: // List
        final len = read() as int;
        final list = <dynamic>[];
        for (var i = 0; i < len; i++) {
          list.add(read());
        }
        return list;

    // --- THIS IS THE FIX ---
      case 6: // Map
        final len = read() as int;
        final map = <dynamic, dynamic>{};
        for (var i = 0; i < len; i++) {
          final key = read();
          final value = read();
          map[key] = value;
        }
        return map;
    // --- END OF FIX ---

      case 100: // Custom Object
        final typeId = read() as int;
        final adapter = _adapters[typeId];
        if (adapter != null) {
          return adapter.read(this);
        } else {
          throw ArgumentError('Cannot read, unknown typeId: $typeId');
        }
      default:
        throw ArgumentError('Cannot read, unknown type: $type');
    }
  }

  /// Reads an integer value.
  int readInt() => read() as int;
}
