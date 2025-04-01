import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class PasswordEncryption {
  static const String _saltKey = 'parent_password_salt';
  static const String _hashKey = 'parent_password_hash';

  static String generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  static String secureHash(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    var result = sha256.convert(bytes).bytes;
    for (var i = 0; i < 1000; i++) {
      result = sha256.convert(result).bytes;
    }
    return base64Encode(result);
  }

  static Future<void> storePassword(String password) async {
    final salt = generateSalt();
    final hashedPassword = secureHash(password, salt);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saltKey, salt);
    await prefs.setString(_hashKey, hashedPassword);
  }

  static Future<bool> verifyPassword(String enteredPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final storedSalt = prefs.getString(_saltKey);
    final storedHash = prefs.getString(_hashKey);
    if (storedSalt == null || storedHash == null) return false;
    final hashedEntered = secureHash(enteredPassword, storedSalt);
    return hashedEntered == storedHash;
  }
}

Future<void> showSetParentPasswordDialog(BuildContext context) async {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Set Parent Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Enter new password'),
              ),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm password'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final password = passwordController.text.trim();
              final confirm = confirmController.text.trim();
              if (password.isEmpty) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Password cannot be empty')),
                  );
                }
                return;
              }
              if (password != confirm) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                }
                return;
              }
              await PasswordEncryption.storePassword(password);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Parent password set!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

Future<bool> showParentLoginDialog(BuildContext context) async {
  final controller = TextEditingController();
  final completer = Completer<bool>();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Enter Parent Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Parent Password'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  resetParentPassword(context).then((_) {
                    completer.complete(false);
                  });
                },
                child: const Text('Forgot Password?'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final isCorrect = await PasswordEncryption.verifyPassword(controller.text.trim());
              if (isCorrect) {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                completer.complete(true);
              } else {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Incorrect password')),
                  );
                }
              }
            },
            child: const Text('Verify'),
          ),
        ],
      );
    },
  );
  return completer.future;
}

Future<void> resetParentPassword(BuildContext context) async {
  final random = Random();
  final a = random.nextInt(10) + 5; // 5-14
  final b = random.nextInt(10) + 3; // 3-12
  final controller = TextEditingController();
  final completer = Completer<void>();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Solve to Reset Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('What is $a × $b?'),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (controller.text.trim() == '${a * b}') {
                Navigator.of(dialogContext).pop();
                _showNewPasswordDialog(context).then((_) {
                  completer.complete();
                });
              } else {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Wrong answer')),
                  );
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      );
    },
  );
  return completer.future;
}

Future<void> _showNewPasswordDialog(BuildContext context) async {
  final newPasswordController = TextEditingController();
  final confirmController = TextEditingController();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Enter New Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm password'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final newPassword = newPasswordController.text.trim();
              final confirm = confirmController.text.trim();
              if (newPassword.isEmpty) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Password cannot be empty')),
                  );
                }
                return;
              }
              if (newPassword != confirm) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                }
                return;
              }
              await PasswordEncryption.storePassword(newPassword);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password Reset!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
