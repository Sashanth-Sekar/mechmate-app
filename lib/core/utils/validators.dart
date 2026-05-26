class AppValidators {
  AppValidators._();

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 10) return 'Enter a valid 10-digit phone number';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? vehicleNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vehicle number is required';
    return null;
  }

  static String? pincode(String? value) {
    if (value == null || value.trim().isEmpty) return 'Pincode is required';
    if (value.trim().length != 6) return 'Enter a valid 6-digit pincode';
    if (int.tryParse(value.trim()) == null) return 'Pincode must be numeric';
    return null;
  }

  static String? year(String? value) {
    if (value == null || value.trim().isEmpty) return 'Year is required';
    final y = int.tryParse(value.trim());
    if (y == null || y < 1990 || y > DateTime.now().year) {
      return 'Enter a valid year (1990–${DateTime.now().year})';
    }
    return null;
  }
}
