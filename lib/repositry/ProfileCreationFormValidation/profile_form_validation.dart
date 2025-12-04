class ProfileFormValidation {
  static validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'This Field is required';
    }
    final namePattern = RegExp(r'^[a-zA-Z\s]+$');
    if (!namePattern.hasMatch(value)) {
      return 'Please enter a valid ${value}';
    }
    return null;
  }

  static cnicValidation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your CNIC';
    }
    final cnicPattern = RegExp(r'^\d{5}-\d{7}-\d{1}$');

    if (!cnicPattern.hasMatch(value)) {
      return 'Please enter a valid CNIC (e.g. 12345-1234567-1)';
    }
    return null;
  }

  static phoneValidation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    final phonePattern = RegExp(r'^[0-9]{11}$');
    if (!phonePattern.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
  }

  static ageValidation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your age';
    }
    final agePattern = RegExp(r'^[0-9]+$');
    if (!agePattern.hasMatch(value)) {
      return 'Please enter a valid age';
    }
  }

  static exceptEveryThing(String? value) {
    if (value == null || value.isEmpty) {
      return 'This Field is required';
    }
    final pattern = RegExp(r'^[a-zA-Z0-9\s]+$');
    if (!pattern.hasMatch(value)) {
      return 'Please enter a valid input';
    }
    return null;
  }
}
