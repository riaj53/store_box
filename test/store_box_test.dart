import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p; // Corrected this line
import 'package:store_box/src/binary/binary_reader.dart';
import 'package:store_box/src/binary/binary_writer.dart';
import 'package:store_box/store_box.dart';
import 'package:test/test.dart';

// --- Test Setup: Define a custom object and its adapter for testing ---
class User {
  final String name;
  final int age;
  User(this.name, this.age);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is User &&
              runtimeType == other.runtimeType &&
              name == other.name &&
              age == other.age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 1;

  @override
  User read(BinaryReader reader) {
    return User(reader.read() as String, reader.read() as int);
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer.write(obj.name);
    writer.write(obj.age);
  }
}

void main() {
  group('StoreBox Tests', () {
    late Directory testDir;
    late StoreBox store;

    // setUpAll runs ONCE before all tests in this group.
    setUpAll(() {
      store = StoreBox();
      store.registerAdapter(UserAdapter());
    });

    // setUp runs before EACH individual test.
    setUp(() async {
      // Create a temporary directory for each test to ensure they are isolated.
      testDir = Directory(p.join(Directory.current.path, 'test_temp_db'));
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
      await testDir.create();
      // Initialize the store with the clean directory path before each test.
      await store.init(testDir.path);
    });

    // tearDown runs after EACH individual test.
    tearDown(() async {
      // Clean up the temporary directory after each test.
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    test('Basic put and get operations work correctly', () async {
      final box = await store.openBox<dynamic>('primitives');

      await box.put('a_string', 'hello world');
      await box.put('an_int', 123);
      await box.put('a_bool', true);

      expect(box.get('a_string'), 'hello world');
      expect(box.get('an_int'), 123);
      expect(box.get('a_bool'), true);
      expect(box.get('non_existent'), isNull);
    });

    test('Custom objects can be stored and retrieved with TypeAdapters',
            () async {
          final box = await store.openBox<User>('users');
          final user = User('Bob', 42);

          await box.put('user_bob', user);
          final retrievedUser = box.get('user_bob');

          expect(retrievedUser, isNotNull);
          expect(retrievedUser, user);
        });

    test('Data persists between box instances (simulates app restart)',
            () async {
          var box = await store.openBox<String>('persist_test');
          await box.put('my_data', 'it should still be here');

          // Re-initialize to simulate a restart (using a new instance variable
          // but still accessing the same singleton).
          final newStoreInstance = StoreBox();
          await newStoreInstance.init(testDir.path);

          box = await newStoreInstance.openBox('persist_test');
          expect(box.get('my_data'), 'it should still be here');
        });

    test('Encrypted box stores and retrieves data correctly', () async {
      final password = utf8.encode('my_secret_password');
      final box =
      await store.openBox<String>('secrets', encryptionKey: password);

      await box.put('api_key', 'super-secret-key-123');
      final retrievedKey = box.get('api_key');

      expect(retrievedKey, 'super-secret-key-123');

      // Verify that the file on disk is not plain text.
      final file = File(p.join(testDir.path, 'secrets.box'));
      final fileContent = await file.readAsBytes();
      // A simple check to ensure the raw content isn't the same as the secret.
      expect(utf8.decode(fileContent, allowMalformed: true),
          isNot('super-secret-key-123'));
    });
  });
}

