import 'package:flutter/material.dart';

typedef DialogBottomSheetListener = bool Function(DraggableScrollableNotification draggableScrollableNotification);

class Dialog {
  final bool isDismissible;
  final bool showCloseButton;
  final Widget? bottomSheetTitle;
  final Color dropDownBackgroundColor;
  final DialogBottomSheetListener? bottomSheetListener;
  final Widget? widget;
  final double? height;

  Dialog({
    Key? key,
    this.isDismissible = true,
    this.showCloseButton = true,
    this.bottomSheetTitle,
    this.dropDownBackgroundColor = Colors.transparent,
    this.bottomSheetListener,
    this.widget,
    this.height,
  });
}

class DialogBottomSheet {
  Dialog dropDown;

  DialogBottomSheet(this.dropDown);

  void showModal(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: const Color(0xffFEFEFE),
      isScrollControlled: true,
      enableDrag: dropDown.isDismissible,
      isDismissible: dropDown.isDismissible,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(15.0))),
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SafeArea(child: DialogBottomSheetMainBody(dropDown: dropDown));
          },
        );
      },
    );
  }
}

class DialogBottomSheetMainBody extends StatefulWidget {
  final Dialog dropDown;

  const DialogBottomSheetMainBody({required this.dropDown, super.key});

  @override
  State<DialogBottomSheetMainBody> createState() => _DialogBottomSheetMainBodyState();
}

class _DialogBottomSheetMainBodyState extends State<DialogBottomSheetMainBody> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: widget.dropDown.bottomSheetListener,
      child: Container(
        height: widget.dropDown.height,
        decoration: const BoxDecoration(
          color: Color(0xffFEFEFE),
          borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Bottom sheet title text
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 16),
                        child: widget.dropDown.bottomSheetTitle ?? Container(),
                      ),
                    ),

                    // Done button
                    Visibility(
                      visible: widget.dropDown.showCloseButton,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.clear, color: Color(0xff888D95)),
                          onPressed: () {
                            _onUnFocusKeyboardAndPop();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
                child: Visibility(
                  visible: widget.dropDown.widget != null ? true : false,
                  child: widget.dropDown.widget != null ? widget.dropDown.widget! : Container(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onUnFocusKeyboardAndPop() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop();
  }
}
