import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:store_box/store_box.dart';

import '../src/binary/binary_reader.dart';
import '../src/binary/binary_writer.dart';

// --- 1. Define a Custom Object ---
class User {
  final String name;
  final int age;
  User(this.name, this.age);
  @override
  String toString() => 'User(name: $name, age: $age)';
}

// --- 2. Create a TypeAdapter for the Custom Object ---
class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 1;

  @override
  User read(BinaryReader reader) {
    final name = reader.read() as String;
    final age = reader.read() as int;
    return User(name, age);
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer.write(obj.name);
    writer.write(obj.age);
  }
}

Future<void> main() async {
  final dbPath = p.join(Directory.current.path, 'store_box_data');
  final dbDir = Directory(dbPath);
  if (await dbDir.exists()) await dbDir.delete(recursive: true);

  // --- 3. Initialize StoreBox and Register Adapters ---
  final store = StoreBox();
  await store.init(dbPath);
  store.registerAdapter(UserAdapter());

  print('--- Testing Custom Objects ---');
  final userBox = await store.openBox<User>('users');
  await userBox.put('user1', User('Alice', 30));
  final retrievedUser = userBox.get('user1');
  print('Retrieved User: $retrievedUser');

  print('\n--- Testing Encryption ---');
  final password = utf8.encode('a_very_strong_password');
  final secretBox = await store.openBox<String>('secrets', encryptionKey: password);
  await secretBox.put('apiKey', '123-ABC-789');
  print('Retrieved API Key: ${secretBox.get('apiKey')}');

  print('\nExample finished successfully!');
}