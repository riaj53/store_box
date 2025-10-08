import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// A secure cipher that handles AES-256 encryption and decryption.
/// It uses a modern authenticated encryption algorithm (AES-CBC with HMAC-SHA256).
class EncryptionCipher {
  final SecretKey _secretKey;
  // Using AES-CBC with PKCS7 padding and HMAC-SHA256 for authentication.
  // This is a standard, secure, and well-vetted algorithm.
  final _algorithm = AesCbc.with256bits(macAlgorithm: Hmac.sha256());

  EncryptionCipher._(this._secretKey);

  /// Creates a cipher by securely deriving a 32-byte key from a password.
  static Future<EncryptionCipher> fromPassword(List<int> password, List<int> salt) async {
    // PBKDF2 is a standard algorithm for turning a password into a secure key.
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000, // A standard number of iterations.
      bits: 256, // 256 bits for AES-256.
    );

    // Correctly derive the key from a List<int> using a SecretKey object.
    final secretKey = SecretKey(password);
    final newKey = await pbkdf2.deriveKey(
      secretKey: secretKey,
      nonce: salt,
    );

    return EncryptionCipher._(newKey);
  }

  /// Encrypts data.
  Future<Uint8List> encrypt(Uint8List bytes) async {
    final secretBox = await _algorithm.encrypt(bytes, secretKey: _secretKey);
    // The nonce (IV) and MAC are combined with the ciphertext.
    // This is crucial for secure decryption.
    return Uint8List.fromList([
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
  }

  /// Decrypts data.
  Future<Uint8List> decrypt(Uint8List bytes) async {
    // The nonce is 16 bytes for AES-CBC.
    final nonce = bytes.sublist(0, 16);
    // The MAC is 32 bytes for HMAC-SHA256.
    final mac = Mac(bytes.sublist(bytes.length - 32));
    final cipherText = bytes.sublist(16, bytes.length - 32);

    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);

    final decrypted = await _algorithm.decrypt(secretBox, secretKey: _secretKey);
    return Uint8List.fromList(decrypted);
  }
}

