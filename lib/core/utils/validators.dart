/// Input validation utilities
class Validators {
  /// Email validation regex
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Password validation regex (at least 8 chars, 1 uppercase, 1 lowercase, 1 number)
  static final RegExp _strongPasswordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$',
  );

  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate strong password
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!_strongPasswordRegex.hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, and number';
    }
    return null;
  }

  /// Validate password confirmation
  static String? validatePasswordConfirm(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, [String fieldName = 'This field']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[\d\s-()]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    if (value.replaceAll(RegExp(r'[\s-()]'), '').length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    return null;
  }

  /// Validate number
  static String? validateNumber(String? value, [String fieldName = 'This field']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  /// Validate positive number
  static String? validatePositiveNumber(String? value, [String fieldName = 'This field']) {
    final numberError = validateNumber(value, fieldName);
    if (numberError != null) return numberError;
    
    final number = double.parse(value!);
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  /// Validate integer
  static String? validateInteger(String? value, [String fieldName = 'This field']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (int.tryParse(value) == null) {
      return 'Please enter a valid whole number';
    }
    return null;
  }

  /// Validate URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  /// Validate date (not in past)
  static String? validateFutureDate(DateTime? value, [String fieldName = 'Date']) {
    if (value == null) {
      return '$fieldName is required';
    }
    if (value.isBefore(DateTime.now())) {
      return '$fieldName cannot be in the past';
    }
    return null;
  }

  /// Validate min length
  static String? validateMinLength(String? value, int minLength, [String fieldName = 'This field']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  /// Validate max length
  static String? validateMaxLength(String? value, int maxLength, [String fieldName = 'This field']) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }
    return null;
  }

  /// Validate range
  static String? validateRange(double? value, double min, double max, [String fieldName = 'Value']) {
    if (value == null) {
      return '$fieldName is required';
    }
    if (value < min || value > max) {
      return '$fieldName must be between $min and $max';
    }
    return null;
  }

  /// Validate quantity
  static String? validateQuantity(String? value) {
    return validatePositiveNumber(value, 'Quantity');
  }

  /// Validate recipe title
  static String? validateRecipeTitle(String? value) {
    return validateMinLength(value, 3, 'Recipe title');
  }

  /// Validate recipe description
  static String? validateRecipeDescription(String? value) {
    return validateMinLength(value, 10, 'Recipe description');
  }

  /// Validate item name
  static String? validateItemName(String? value) {
    return validateMinLength(value, 2, 'Item name');
  }
}

