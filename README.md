store_box: A Modern, Simple, and Secure Flutter Database
A fast, enjoyable, and secure NoSQL database for Flutter & Dart, inspired by Hive. Provides persistent local storage for any Dart object with a simple API and built-in encryption, without requiring code generation.

store_box is designed to be a lightweight, modern alternative to Hive for developers who want a simple, powerful local database without the extra build steps.

Why Choose store_box?
🚀 Zero Boilerplate: No build_runner, no generated .g.dart files. Just write your TypeAdapter and you're ready to go.

💡 Simple, Modern API: The API is intuitive and easy to learn, whether you're a beginner or an expert.

🔒 Secure by Default: Built-in AES-256 encryption is easy to enable for sensitive data.

❤️ Pure Dart & Flutter: Works everywhere Flutter does—iOS, Android, Web, Desktop—with no platform-specific dependencies.

Feature Comparison
Feature

✅ store_box

🐝 Hive

Setup

Simple, no code generation required

Requires hive_generator & build_runner

Custom Objects

Supported via manual TypeAdapter

Supported via generated TypeAdapter

Encryption

Yes (AES-256)

Yes (AES-256)

API

Modern & intuitive

Well-established & powerful

Performance

Fast for most common use cases

Highly optimized for large-scale datasets

Getting Started
1. Add to pubspec.yaml
   Add this to your package's pubspec.yaml file. Make sure to get the latest version from pub.dev.

dependencies:
store_box: ^1.0.0
path_provider: ^2.0.0 # To find a safe directory for the database

2. Initialize in Your App
   You must initialize store_box before you can use it. This should be done once when your app starts.

// main.dart
import 'package:flutter/material.dart';
import 'package:store_box/store_box.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
// Ensure Flutter is initialized
WidgetsFlutterBinding.ensureInitialized();

// Get a safe directory for the database
final appDocumentDir = await getApplicationDocumentsDirectory();

// Initialize StoreBox
await StoreBox().init(appDocumentDir.path);

// Register any custom adapters
StoreBox().registerAdapter(UserAdapter());

runApp(const MyApp());
}

Usage Examples
1. Basic Operations (Get & Put)
   A "box" is like a table in a SQL database. You can open as many as you need.

// Open a box to store settings
final settingsBox = await StoreBox().openBox('settings');

// Save a value
await settingsBox.put('darkMode', true);

// Read a value
final bool isDarkMode = settingsBox.get('darkMode') ?? false;
print('Dark Mode is enabled: $isDarkMode');

2. Storing Custom Objects
   You can store any Dart object by creating a TypeAdapter for it.

// 1. Your custom class
class User {
final String name;
final int age;
User(this.name, this.age);
}

// 2. Its TypeAdapter
class UserAdapter extends TypeAdapter<User> {
@override
final int typeId = 1; // Must be unique for each adapter

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

// 3. Register the adapter in main() (see Getting Started)

// 4. Use it!
final userBox = await StoreBox().openBox<User>('users');
await userBox.put('user_123', User('Alice', 30));
final alice = userBox.get('user_123');
print(alice?.name); // Prints "Alice"

3. Using Encryption
   Protect sensitive data by providing an encryptionKey when you open a box.

import 'dart:convert';

// Generate a secure key. In a real app, store this in secure storage.
final encryptionKey = utf8.encode('a_very_strong_32_byte_secret_key');

// Open an encrypted box
final secretBox = await StoreBox().openBox('secrets', encryptionKey: encryptionKey);

await secretBox.put('apiKey', '123-ABC-789');
print(secretBox.get('apiKey')); // Prints "123-ABC-789"

The data in the secrets.box file on disk will be completely unreadable without the key.

Contributing
Contributions are welcome! If you find a bug or have a feature request, please open an issue on GitHub.

License
This project is licensed under the MIT License - see the LICENSE file for details.