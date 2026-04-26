import 'package:flutter/material.dart';
import 'package:blotpay/styles/colors.dart';


Widget customDropDownField(
    {String? title,
      String? initialValue,
      List<String>? items,
      required Function(String?)? onChanged,
      BuildContext? context}) {
  return  Column(
    children: [
      Container(
        alignment: Alignment.centerLeft,

        child: Text(
          title!,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: black,
          ),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(
            vertical: 5, horizontal: 10),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: primaryColor, width: 2.0, style: BorderStyle.solid),
            borderRadius: const BorderRadius.all(Radius.circular(5.0))
          )
          // border: Border(b)
        ),
        width: MediaQuery.of(context!).size.width,
        child: DropdownButtonHideUnderline(
          child: DropdownButton(
            value: initialValue,
            icon: const Icon(Icons.keyboard_arrow_down),
            dropdownColor: white,
            focusColor: lightGrey,
            items: items?.map((String items) {
              return DropdownMenuItem(
                  value: items, child: Text(items));
            }).toList(),
            // isDense: true,
            // isExpanded: true,
            onChanged: onChanged,

          ),
        ),
      )
    ],
  );
}
