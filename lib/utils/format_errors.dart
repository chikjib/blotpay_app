List<String> extractErrorMessages(Map<String, dynamic> errorData) {
  final List<String> messages = [];

  String prettify(String key) {
    // Replace underscores with spaces and capitalize each word
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
    word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  errorData.forEach((key, value) {
    if (value is List) {
      for (final msg in value) {
        messages.add('${prettify(key)}: $msg');
      }
    }
    else if (value is Map<String, dynamic>) {
      value.forEach((subKey, subValue) {
        // Collapse cases like referral.referral or password.password
        final String finalKey =
        key == subKey ? key : '$key $subKey';

        if (subValue is List) {
          for (final msg in subValue) {
            messages.add('${prettify(finalKey)}: $msg');
          }
        } else {
          messages.add('${prettify(finalKey)}: $subValue');
        }
      });
    }
    else {
      messages.add('${prettify(key)}: $value');
    }
  });

  return messages;
}