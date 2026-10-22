import 'package:get/get.dart';

class AppValidators {
  /// Validates Username:
  /// Must contain:
  /// - At least one lowercase letter (a-z)
  /// - At least one uppercase letter (A-Z)
  /// - At least one digit (0-9)
  /// - At least one special character (e.g. @, _, #, $, ., !, %, &, *)
  /// - Minimum 4 characters long
  /// - No spaces
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a username.';
    }
    final username = value.trim();

    if (username.contains(' ')) {
      return 'Username cannot contain spaces.';
    }
    if (username.length < 4) {
      return 'Username must be at least 4 characters long.';
    }
    if (!RegExp(r'[a-z]').hasMatch(username)) {
      return 'Username must contain at least one lowercase letter (a-z).';
    }
    if (!RegExp(r'[A-Z]').hasMatch(username)) {
      return 'Username must contain at least one uppercase letter (A-Z).';
    }
    if (!RegExp(r'[0-9]').hasMatch(username)) {
      return 'Username must contain at least one digit (0-9).';
    }
    if (!RegExp(r'[^a-zA-Z0-9\s]').hasMatch(username)) {
      return 'Username must contain at least one special character (e.g. @, _, #,  , !).';
    }
    return null;
  }

  /// Validates Email:
  /// Must be a valid email address format
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an email address.';
    }
    final email = value.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email) || !GetUtils.isEmail(email)) {
      return 'Please enter a valid email address (e.g. user@example.com).';
    }
    return null;
  }

  /// Validates Password:
  /// Must contain:
  /// - At least one lowercase letter (a-z)
  /// - At least one uppercase letter (A-Z)
  /// - At least one digit (0-9)
  /// - At least one special character (e.g. @, #, $, !, %, &, *)
  /// - Minimum 6 characters long
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long.';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter (a-z).';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter (A-Z).';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one digit (0-9).';
    }
    if (!RegExp(r'[^a-zA-Z0-9\s]').hasMatch(value)) {
      return 'Password must contain at least one special character (e.g. @, #,  !).';
    }
    return null;
  }

  /// Validates Full Name
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name.';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long.';
    }
    return null;
  }
}
