class Validations {
  validateText(String? value, String labelName) {
    if (value == null || value.isEmpty) {
      return '-$labelName is required';
    }
  }

  validateEmail(String? value, String labelName) {
    var emailRegExp = RegExp(r'^[\w-\.]+@[a-zA-Z]+\.[a-zA-Z]{2,}$')
        .hasMatch(value.toString());
    if (value == null || value.isEmpty) {
      return '-$labelName is required';
    } else if (emailRegExp == false) {
      return '-This is an invalid email address';
    }
  }

  validatePhone(String? value, String labelName) {
    var phoneRegExp = RegExp(r'^(?:[0])?[0-9]{11}$').hasMatch(value.toString());
    if (value == null || value.isEmpty) {
      return '-$labelName is required';
    } else if (value.length < 11 || value.length > 11) {
      return '$labelName length must be exactly 11';
    } else if (phoneRegExp == false) {
      return '-This is an invalid phone number';
    }
  }

  String validateNumber(String? numb) {
    String newNumber;
    String number = numb!.trim();
    if (number.substring(0, 3) == "234") {
      newNumber = "0${number
              .substring(3, number.length)
              .replaceAll(RegExp(r'[^0-9]'), '')}";
    } else if (number.substring(0, 4) == "+234") {
      newNumber = "0${number
              .substring(4, number.length)
              .replaceAll(RegExp(r'[^0-9]'), '')}";
    } else {
      newNumber = number.replaceAll(RegExp(r'[^0-9]'), '').toString();
    }
    return newNumber;
  }

  validatePassword(String? value, String labelName) {
    if (value == null || value.isEmpty) {
      return '-$labelName is required';
    } else if (value.length < 8) {
      return '-Password is too short';
    }
  }
  passwordMatch(String? newPassword, String confirmPasswordLabelName, String? confirmPassword){
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return '$confirmPasswordLabelName is required';
    } else if (confirmPassword.length < 8) {
      return '-Password is too short';
    }else if(newPassword != confirmPassword){
      return '-Password does not match';
    }
  }

  checkPassword(String? newPassword, String newPasswordLabelName){
    if (newPassword!.length < 8) {
      return '-Password is too short';
    }
  }

  pinMatch(String? newPin, String confirmPinLabelName, String? confirmPin){
    if (confirmPin == null || confirmPin.isEmpty) {
      return '$confirmPinLabelName is required';
    } else if (confirmPin.length < 4) {
      return '-Pin is too short';
    }else if(newPin != confirmPin){
      return '-Pin does not match';
    }
  }

  validateNin(String? value, String labelName) {
    var phoneRegExp = RegExp(r'^(?:[0])?[0-9]{11}$').hasMatch(value.toString());
    if (value == null || value.isEmpty) {
      return '-$labelName is required';
    } else if (value.length < 11 || value.length > 11) {
      return '$labelName length must be exactly 11 digits';
    } else if (phoneRegExp == false) {
      return '-This is an invalid nin';
    }
  }
  validateBvn(String? value, String labelName) {
    var phoneRegExp = RegExp(r'^(?:[0])?[0-9]{11}$').hasMatch(value.toString());
    if (value == null || value.isEmpty) {
      return '-$labelName is required';
    } else if (value.length < 11 || value.length > 11) {
      return '$labelName length must be exactly 11 digits';
    } else if (phoneRegExp == false) {
      return '-This is an invalid bvn';
    }
  }

  validateAtc(String? value, String labelName) {
    if (value == null || value.isEmpty) {
      return '-$labelName is required';
    } else if(int.parse(value) < 1000){
      return "-You can't transfer less than N1,000";
    }
  }

  validateAmount(String? value, String labelName) {
    if (value == null || value.isEmpty) {
      return '-$labelName is required';
    } else if(int.parse(value) < 50){
      return "-Amount cannot be less than 50 naira";
    }
  }
}
