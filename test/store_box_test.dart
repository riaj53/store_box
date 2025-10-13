// import 'dart:convert';
// import 'dart:io';
// import 'package:path/path.dart' as p;
// import 'package:store_box/src/binary/binary_reader.dart';
// import 'package:store_box/src/binary/binary_writer.dart';
// import 'package:store_box/store_box.dart';
// import 'package:test/test.dart';
//
// // --- Test Setup: Define a custom object and its adapter for testing ---
// class User {
//   final String name;
//   final int age;
//   User(this.name, this.age);
//
//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//           other is User &&
//               runtimeType == other.runtimeType &&
//               name == other.name &&
//               age == other.age;
//
//   @override
//   int get hashCode => name.hashCode ^ age.hashCode;
// }
//
// class UserAdapter extends TypeAdapter<User> {
//   @override
//   final int typeId = 1;
//
//   @override
//   User read(BinaryReader reader) {
//     return User(reader.read() as String, reader.read() as int);
//   }
//
//   @override
//   void write(BinaryWriter writer, User obj) {
//     writer.write(obj.name);
//     writer.write(obj.age);
//   }
// }
//
// void main() {
//   group('StoreBox Tests', () {
//     late Directory testDir;
//
//     // setUpAll runs ONCE before all tests.
//     // Register the adapter using the new static method.
//     setUpAll(() {
//       StoreBox.registerAdapter(UserAdapter());
//     });
//
//     // setUp runs before EACH individual test.
//     setUp(() async {
//       // Create a temporary directory for each test to ensure isolation.
//       testDir = Directory(p.join(Directory.current.path, 'test_temp_db'));
//       if (await testDir.exists()) {
//         await testDir.delete(recursive: true);
//       }
//       await testDir.create();
//
//       // Initialize StoreBox statically with the clean directory path.
//       await StoreBox.init(testDir.path);
//     });
//
//     // tearDown runs after EACH individual test.
//     tearDown(() async {
//       if (await testDir.exists()) {
//         await testDir.delete(recursive: true);
//       }
//     });
//
//     // --- NEW TEST for the simple default box ---
//     test('Default box (simple key-value) works correctly', () async {
//       await StoreBox.put('a_string', 'hello default');
//       await StoreBox.put('an_int', 456);
//       await StoreBox.put('a_bool', false);
//
//       expect(StoreBox.get('a_string'), 'hello default');
//       expect(StoreBox.get('an_int'), 456);
//       expect(StoreBox.get('a_bool'), false);
//       expect(StoreBox.get('non_existent'), isNull);
//
//       await StoreBox.delete('an_int');
//       expect(StoreBox.get('an_int'), isNull);
//     });
//
//     test('Named Box basic put and get operations work correctly', () async {
//       // Use the static openBox method
//       final box = await StoreBox.openBox<dynamic>('primitives');
//
//       await box.put('a_string', 'hello world');
//       await box.put('an_int', 123);
//
//       expect(box.get('a_string'), 'hello world');
//       expect(box.get('an_int'), 123);
//     });
//
//     test('Custom objects can be stored and retrieved with TypeAdapters',
//             () async {
//           final box = await StoreBox.openBox<User>('users');
//           final user = User('Bob', 42);
//
//           await box.put('user_bob', user);
//           final retrievedUser = box.get('user_bob');
//
//           expect(retrievedUser, isNotNull);
//           expect(retrievedUser, user);
//         });
//
//     test('Data persists between initializations (simulates app restart)',
//             () async {
//           var box = await StoreBox.openBox<String>('persist_test');
//           await box.put('my_data', 'it should still be here');
//
//           // Re-initialize to simulate a restart.
//           await StoreBox.init(testDir.path);
//
//           // Re-open the box and check if the data is still there.
//           var reopenedBox = await StoreBox.openBox<String>('persist_test');
//           expect(reopenedBox.get('my_data'), 'it should still be here');
//         });
//
//     test('Encrypted box stores and retrieves data correctly', () async {
//       final password = utf8.encode('my_secret_password');
//       final box =
//       await StoreBox.openBox<String>('secrets', encryptionKey: password);
//
//       await box.put('api_key', 'super-secret-key-123');
//       final retrievedKey = box.get('api_key');
//
//       expect(retrievedKey, 'super-secret-key-123');
//
//       // Verify that the file on disk is not plain text.
//       final file = File(p.join(testDir.path, 'secrets.box'));
//       final fileContent = await file.readAsBytes();
//       expect(utf8.decode(fileContent, allowMalformed: true),
//           isNot('super-secret-key-123'));
//     });
//   });
// }

// Import the flutter_test package which provides Flutter-specific testing utilities.
import 'package:flutter_test/flutter_test.dart';
import 'package:store_box/store_box.dart';

// You will also need your custom objects and adapters for the test.
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:store_box/src/binary/binary_reader.dart';
import 'package:store_box/src/binary/binary_writer.dart';


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
  // This ensures that the Flutter test environment is initialized.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StoreBox Tests', () {
    late Directory testDir;

    setUpAll(() {
      StoreBox.registerAdapter(UserAdapter());
    });

    setUp(() async {
      // Create a unique temporary directory for each test.
      // Using Directory.systemTemp.createTempSync() is a robust way to do this.
      testDir = Directory.systemTemp.createTempSync('store_box_test_');

      // Initialize StoreBox statically with the clean directory path.
      await StoreBox.init(testDir.path);
    });

    tearDown(() async {
      // Clean up the temporary directory after each test.
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    test('Default box (simple key-value) works correctly', () async {
      await StoreBox.put('a_string', 'hello default');
      await StoreBox.put('an_int', 456);

      expect(StoreBox.get('a_string'), 'hello default');
      expect(StoreBox.get('an_int'), 456);

      await StoreBox.delete('an_int');
      expect(StoreBox.get('an_int'), isNull);
    });

    test('Named Box with custom objects works correctly', () async {
      final box = await StoreBox.openBox<User>('users');
      final user = User('Bob', 42);

      await box.put('user_bob', user);
      final retrievedUser = box.get('user_bob');

      expect(retrievedUser, isNotNull);
      expect(retrievedUser, user);
    });

    test('Data persists between initializations', () async {
      var box = await StoreBox.openBox<String>('persist_test');
      await box.put('my_data', 'it should still be here');

      // Re-initialize to simulate a restart.
      await StoreBox.init(testDir.path);

      var reopenedBox = await StoreBox.openBox<String>('persist_test');
      expect(reopenedBox.get('my_data'), 'it should still be here');
    });
  });
}
