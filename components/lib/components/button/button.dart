import 'package:flutter/material.dart';

import 'button_dls.dart';
import 'button_size.dart';
import 'button_status.dart';
import 'button_type.dart';

///
/// Desenvolvimento - Marcelo Moreto - 07/08/2023
class Button extends StatefulWidget {
  const Button({
    super.key,
    required this.text,
    this.buttonSize = ButtonSize.small,
    this.buttonType = ButtonType.primary,
    this.buttonStatus = ButtonStatus.enabled,
    required this.onPressed,
    this.width = double.infinity,
  });

  final ButtonSize buttonSize;
  final ButtonType buttonType;
  final ButtonStatus buttonStatus;

  final String text;
  final VoidCallback onPressed;
  final double width;

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  //   Color textColor = const Color(0xff3354FD);
  //   Color backgroundColor = const Color(0xfffdf429);
  //   double fontSize = 0.0;
  //   double heigh = 0.0;

  //   void _getButtonValuesBySize(ButtonSize buttonSize) {
  //     try {
  //       switch (buttonSize) {
  //         case ButtonSize.small:
  //           fontSize = 12.0;
  //           heigh = 32.0;
  //           break;
  //         case ButtonSize.regular:
  //           fontSize = 14.0;
  //           heigh = 40.0;
  //           break;
  //         case ButtonSize.large:
  //           fontSize = 16.0;
  //           heigh = 48.0;
  //           break;
  //       }
  //     } catch (ex) {
  //       // BBLog.print('${super.runtimeType} - $ex', title: kErro, name: kCmp);
  //     }
  //   }

  // void _getButtonType(ButtonType buttonType, ButtonStatus buttonStatus) {
  //   String tmpBackgroundColor = kVazio;
  //   String tmpTextColor = kVazio;
  //   try {
  //     switch (buttonStatus) {
  //       case ButtonStatus.disabled:
  //         tmpBackgroundColor = colorShadesDls.shades.onSurface![kDuzentos].toString();
  //         tmpTextColor = colorShadesDls.shades.onSurface![kQuatrocentos].toString();
  //         backgroundColor = Color(Util.getColor(tmpBackgroundColor));
  //         textColor = Color(Util.getColor(tmpTextColor));
  //         break;

  //       case ButtonStatus.enabled:
  //         switch (buttonType) {
  //           case ButtonType.primary:
  //             tmpBackgroundColor = colorShadesDls.shades.primary![kTrezentos].toString();
  //             tmpTextColor = colorShadesDls.shades.secondary![kSeiscentos].toString();
  //             backgroundColor = Color(Util.getColor(tmpBackgroundColor));
  //             textColor = Color(Util.getColor(tmpTextColor));
  //             break;
  //           case ButtonType.secondary:
  //             tmpBackgroundColor = colorShadesDls.shades.secondary![kDuzentos].toString();
  //             tmpTextColor = colorShadesDls.shades.secondary![kSeiscentos].toString();
  //             backgroundColor = Color(Util.getColor(tmpBackgroundColor));
  //             textColor = Color(Util.getColor(tmpTextColor));
  //             break;
  //           case ButtonType.criticalPrimary:
  //             tmpBackgroundColor = colorShadesDls.shades.critical![kSeiscentos].toString();
  //             tmpTextColor = colorShadesDls.shades.critical!['000'].toString();
  //             backgroundColor = Color(Util.getColor(tmpBackgroundColor));
  //             textColor = Color(Util.getColor(tmpTextColor));
  //             break;
  //           case ButtonType.criticalSecondary:
  //             tmpBackgroundColor = colorShadesDls.shades.critical![kDuzentos].toString();
  //             tmpTextColor = colorShadesDls.shades.critical![kSeiscentos].toString();
  //             backgroundColor = Color(Util.getColor(tmpBackgroundColor));
  //             textColor = Color(Util.getColor(tmpTextColor));
  //             break;
  //         }
  //     }
  //   } catch (ex) {
  //     // BBLog.print('${super.runtimeType} - $ex', title: kErro, name: kCmp);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return ButtonDls(
      text: widget.text,
      // textColor: textColor,
      // backgroundColor: backgroundColor,
      onPressed: widget.buttonStatus == ButtonStatus.enabled ? widget.onPressed : () {},
      // heigh: heigh,
      width: widget.width,
      // fontSize: fontSize,
    ).getButtonPrimary(context);
  }
}
