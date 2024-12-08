// Haveno App extends the features of Haveno, supporting mobile devices and more.
// Copyright (C) 2024 Kewbit (https://kewbit.org)
// Source Code: https://git.haveno.com/haveno/haveno-app.git
//
// Author: Kewbit
//    Website: https://kewbit.org
//    Contact Email: me@kewbit.org
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.


import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:haveno_app/services/secure_storage_service.dart';
import 'package:haveno_app/utils/database_helper.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';

class SecurityService {
  final SecureStorageService _secureStorage = SecureStorageService();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<void> setupUserPassword(String userPassword) async {
    final salt = _generateSalt();
    final hashedPassword = _hashPassword(userPassword, salt);
    final encryptedPassword = _encrypt('$salt:$hashedPassword', userPassword);
    await _secureStorage.writeUserPassword(encryptedPassword);
  }

  Future<bool> authenticateUserPassword(String inputPassword) async {
    final encryptedPassword = await _secureStorage.readUserPassword();
    if (encryptedPassword == null) {
      return false;
    }

    final decryptedPassword = _decrypt(encryptedPassword, inputPassword);
    if (decryptedPassword == null) {
      return false;
    }

    final parts = decryptedPassword.split(':');
    if (parts.length != 2) {
      return false;
    }

    final salt = parts[0];
    final storedHashedPassword = parts[1];
    final inputHashedPassword = _hashPassword(inputPassword, salt);
    return storedHashedPassword == inputHashedPassword;
  }

  String _generateSalt([int length = 16]) {
    final random = Random.secure();
    final saltBytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Url.encode(saltBytes);
  }

  String _hashPassword(String password, String salt) {
    final saltBytes = base64Url.decode(salt);
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(saltBytes, 10000, 32));
    final key = pbkdf2.process(utf8.encode(password));
    return base64Url.encode(key);
  }

  // Encrypts a value using AES
  String _encrypt(String value, String password) {
    final key = _deriveKey(password);
    final iv = _generateIV();
    final cipher = _initCipher(true, key, iv);
    final input = utf8.encode(value);
    final encrypted = cipher.process(input);
    final encryptedData = base64Url.encode(encrypted);
    final encodedIV = base64Url.encode(iv);
    return '$encodedIV:$encryptedData';
  }

  // Decrypts a value using AES
  String? _decrypt(String encryptedValue, String password) {
    try {
      final parts = encryptedValue.split(':');
      if (parts.length != 2) {
        return null;
      }
      final iv = base64Url.decode(parts[0]);
      final encryptedData = base64Url.decode(parts[1]);
      final key = _deriveKey(password);
      final cipher = _initCipher(false, key, iv);
      final decrypted = cipher.process(encryptedData);
      return utf8.decode(decrypted);
    } catch (e) {
      print('Decryption failed: $e');
      return null;
    }
  }

  // derives an AES key from the password using PBKDF2
  KeyParameter _deriveKey(String password, {int iterations = 10000, int keyLength = 32}) {
    final salt = utf8.encode('my_salt'); // use fix salt no issue
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, keyLength));
    final key = pbkdf2.process(utf8.encode(password));
    return KeyParameter(key);
  }

  // denerates an AES cipher for encryption or decryption
  PaddedBlockCipher _initCipher(bool forEncryption, KeyParameter key, Uint8List iv) {
    final params = PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
        ParametersWithIV<KeyParameter>(key, iv), null);
    final cipher = PaddedBlockCipher('AES/CBC/PKCS7');
    cipher.init(forEncryption, params);
    return cipher;
  }

  // Generates a random IV for AES encryption
  Uint8List _generateIV([int length = 16]) {
    final random = Random.secure();
    final iv = List<int>.generate(length, (_) => random.nextInt(256));
    return Uint8List.fromList(iv);
  }

  Future<void> resetAppData() async {
    // Wipe the secure storage
    await _secureStorage.deleteAll();
    // Wipe the database
    await _databaseHelper.destroyDatabase();
  }
}
