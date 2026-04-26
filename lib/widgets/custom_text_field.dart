import 'package:flutter/material.dart';
import 'package:blotpay/styles/colors.dart';
import 'package:flutter/services.dart';

Widget customTextField(
    {String? title,
    String? hint,
    TextEditingController? controller,
    FormFieldValidator<String>? validator,
    bool enabled = true,
    bool readOnly = false,
    int? maxLines = 1,
    TextInputType? type = TextInputType.text,
      AutovalidateMode? autoValidate,
    Icon? myIcon,
      IconButton? suffixIcon,
      bool walletShow = false,
      String walletBalance = "",
    Function(String?)? onChanged,
    bool obscure = false,
      List<TextInputFormatter>? inputFormatters,
    }) {
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title!,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: black,
              ),
            ),
          ),
          walletShow ? Text(
            walletBalance != "*****" ? "Balance: $walletBalance" : "*****",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              fontFamily: 'Roboto',
              color: black,
            ),
          )
              : const SizedBox()
        ],
      ),
      Container(
        alignment: Alignment.centerLeft,
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.transparent
        ),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          autovalidateMode: autoValidate,
          keyboardType: type,
          obscureText: obscure,
          enabled: enabled,
          readOnly: readOnly,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            hintText: hint,
            border: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColor, width: 2.0),
                borderRadius: BorderRadius.circular(8.0)),
            errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: red, width: 2.0),
                borderRadius: BorderRadius.circular(8.0)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColor, width: 2.0),
                borderRadius: BorderRadius.circular(8.0)),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColor, width: 2.0),
                borderRadius: BorderRadius.circular(8.0)),
            prefixIcon: myIcon,
            suffixIcon: suffixIcon,

          ),
          validator: validator,

          // onChanged: ,
        ),
      )
    ],
  );
}
