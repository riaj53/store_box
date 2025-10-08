import 'binary/binary_reader.dart';
import 'binary/binary_writer.dart';

/// A `TypeAdapter` allows you to serialize and deserialize any custom object.
abstract class TypeAdapter<T> {
  /// A unique ID for this type.
  int get typeId;

  /// Called to read an object from binary.
  T read(BinaryReader reader);

  /// Called to write an object to binary.
  void write(BinaryWriter writer, T obj);
}