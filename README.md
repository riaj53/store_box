
## StoreBox
![StoreBox Logo](https://raw.githubusercontent.com/riaj53/store_box/main/store_box.png)

[![pub version](https://img.shields.io/pub/v/store_box?color=blue)](https://pub.dev/packages/store_box)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![style: lints](https://img.shields.io/badge/style-lints-40c4ff.svg)](https://pub.dev/packages/lints)

A fast, enjoyable, and secure NoSQL database for Flutter & Dart. Store any Dart object with a simple, modern API and built-in encryption.**

`store_box` is designed to be a lightweight and powerful local database, focusing on a simple and powerful developer experience without requiring code generation.

## Why Choose `store_box`?
🚀 Zero Boilerplate: No `build_runner`, no generated `.g.dart` files. Just write your `TypeAdapter` and you're ready to go.

💡 Simple, Modern API: The static API is intuitive and easy to learn, whether you're a beginner or an expert.

🔒 Secure by Default: Built-in AES-256 encryption is easy to enable for sensitive data.

❤️ Flutter First: Built for Flutter. Works everywhere Flutter does—iOS, Android, Web, Desktop.


## Getting Started


### 1. Add to `pubspec.yaml`

Add `store_box` to your package's `pubspec.yaml` file.

```pubspec.yaml
dependencies:
  store_box: ^2.0.0 
  ```


## 2. Initialize in Your App

You must initialize store_box before your app starts. This prepares the database for use and should be done once.

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:store_box/store_box.dart';

void main() async {
  // Required for all Flutter apps
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize StoreBox. That's it!
  await StoreBox.init();

  runApp(const MyApp());
}
```
## How to Use
### 1. For Beginners:  Simple Key-Value Storage
This is the easiest way to use `store_box`. It's perfect for saving simple data like user settings, session tokens, or flags without any extra setup.

After you `init()` the package, you can immediately use the static `put()` and `get()` methods anywhere in your app.

```dart
// Save a boolean value to the default storage
await StoreBox.put('darkMode', true);

// Save a username
await StoreBox.put('username', 'Alice');

// Read the values back
final bool isDarkMode = StoreBox.get('darkMode') ?? false;
final String? user = StoreBox.get('username');

print('Dark Mode is enabled: $isDarkMode');
print('Current user: $user');

```
You can store any basic Dart type: `String`, `int`, `double`, `bool`, `List`, and `Map`.
# For Advanced Users: Storing Custom Objects

When you need to store your own data models (like a `User` or `Product class`), you need to tell store_box how to save and load them. You do this by creating a `TypeAdapter`.

## Step 1: Create Your Model and TypeAdapter
A `TypeAdapter` is an instruction manual that `store_box` uses to understand your custom object.

```// lib/user.dart
import 'package:store_box/store_box.dart';
import 'package:store_box/src/binary/binary_reader.dart';
import 'package:store_box/src/binary/binary_writer.dart';

// Your custom class
class User {
  final String name;
  final int age;
  User({required this.name, required this.age});
}

// The instruction manual for the User class
class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 1; // Each type needs a unique, positive ID

  @override
  User read(BinaryReader reader) {
    // Read the fields in the exact same order you wrote them
    final name = reader.read() as String;
    final age = reader.read() as int;
    return User(name: name, age: age);
  }

  @override
  void write(BinaryWriter writer, User obj) {
    // Write the fields of the object
    writer.write(obj.name);
    writer.write(obj.age);
  }
}
```

## Step 2: Register the Adapter
In your `main.dart` file, register the adapter after you initialize `StoreBox`. This should only be done once.

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StoreBox.init();

  // Register your adapter so StoreBox knows about it
  StoreBox.registerAdapter(UserAdapter());

  runApp(const MyApp());
}
```
## Step 3: Open a Box and Use It
Now you can open a dedicated, typed "box" to store your custom objects.

```dart
// Open a box specifically for User objects
final userBox = await StoreBox.openBox<User>('users');

// Save a User object
await userBox.put('user_123', User(name: 'Alice', age: 30));

// Read the User object back
final alice = userBox.get('user_123');
print(alice?.name); // Prints "Alice"
```

## 3. Using Encryption
Protect sensitive data by providing an `encryptionKey` when you open a box. This works for both simple and custom object boxes.

```dart
import 'dart.convert';

// Key must be 32 bytes for AES-256.
// For production, use a secure key management strategy.
final encryptionKey = utf8.encode('a_very_strong_32_byte_secret_key');

final secretBox = await StoreBox.openBox(
  'secrets',
  encryptionKey: encryptionKey,
);

await secretBox.put('apiKey', '123-ABC-789');
print(secretBox.get('apiKey')); // Prints "12-ABC-789"
```
## Coming Soon!
An optional code generator package (`store_box_generator`) is in development to make working with custom objects even easier!
## Contributing

Contributions are welcome! If you find a bug or have a feature request, please open an issue on GitHub.


## License

MIT License

Copyright (c) 2025 Riazul Islam

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
