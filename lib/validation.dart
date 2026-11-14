// Input validation for lead fields. Pure functions, no UI dependency,
// so they are unit tested directly.

/// Digits only, so "+880 1712-345678" and "8801712345678" compare equal.
String normalizePhoneDigits(String? phone) {
  if (phone == null) return '';
  return phone.replaceAll(RegExp(r'[^0-9]'), '');
}

/// A usable WhatsApp number: 7 to 15 digits once spaces, dashes, plus
/// signs and brackets are stripped. Returns an error message or null.
String? validatePhone(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final digits = normalizePhoneDigits(value);
  if (digits.length < 7) {
    return 'Phone number looks too short';
  }
  if (digits.length > 15) {
    return 'Phone number looks too long';
  }
  return null;
}

/// Deal value must be a positive number when given. Returns an error
/// message or null.
String? validateDealValue(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final parsed = double.tryParse(value.trim());
  if (parsed == null) return 'Enter a number, for example 5000';
  if (parsed <= 0) return 'Deal value must be more than 0';
  return null;
}

/// Lead name: required, and capped so one paste cannot break the list.
String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) return 'Name is required';
  if (value.trim().length > 80) return 'Name is too long (max 80 characters)';
  return null;
}
