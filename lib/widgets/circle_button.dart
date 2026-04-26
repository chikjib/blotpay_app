import 'package:flutter/material.dart';

import '../styles/colors.dart';

class CircleButton extends StatelessWidget {
  const CircleButton({super.key, this.onTap, this.icon});

  final GestureTapCallback? onTap;
  final Icon? icon;

  @override
  Widget build(BuildContext context) {
    double outerSize = 120.0;
    double innerSize = 80.0;

    return InkResponse(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: outerSize,
            height: outerSize,
            decoration: BoxDecoration(
              border: Border.all(color: primaryColor,width: 1.5),
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),

          Positioned(
            top:20,
              left: 0,
              right: 0,
              child: Container(
                width: innerSize,
                height: innerSize,
                decoration: BoxDecoration(
                  border: Border.all(color: grey,width: 1.5),
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: icon,
              )
          )
        ],
      )



    );
  }
}