import 'package:commons/constants.dart';
import 'package:flutter/material.dart';

import '../../../theme/theme.dart' as app_theme;
import '../../button/button.dart';
import '../../button/button_size.dart';
import '../../button/button_type.dart';
import '../dialog_bottom_sheet/dialog_bottom_sheet.dart';
import 'dialog_bottom_sheet_warning_status.dart';
import 'dialog_bottom_sheet_warning_type.dart';
import 'dialog_bottom_sheet_warning_type_buttons.dart';

class DialogWarning {
  final bool isDismissible;
  final DialogBottomSheetListener? bottomSheetListener;
  final Widget? customBody;
  final String title;
  final String? titleOverline;
  final String? description;
  final IconData? icon;
  final String titleButtonPrimary;
  final String? titleButtonSecondary;
  final VoidCallback? onPressedPrimary;
  final VoidCallback? onPressedSecondary;
  final VoidCallback? onPressedIcon;
  final double widthButtons;
  final DialogBottomSheetStatus? statusDialog;
  final DialogBottomSheetType? typeDialog;
  final DialogBottomSheetTypeButtons? typeButtonsDialog;

  DialogWarning({
    Key? key,
    this.isDismissible = true,
    this.bottomSheetListener,
    this.customBody,
    required this.title,
    this.titleOverline,
    this.description,
    this.icon,
    required this.titleButtonPrimary,
    this.titleButtonSecondary,
    this.widthButtons = double.infinity,
    this.onPressedPrimary,
    this.onPressedSecondary,
    this.onPressedIcon,
    this.statusDialog = DialogBottomSheetStatus.statusDefault,
    this.typeDialog = DialogBottomSheetType.compact,
    this.typeButtonsDialog = DialogBottomSheetTypeButtons.singleButton,
  });
}

class DialogBottomSheetWarning {
  DialogWarning dialogWarning;

  DialogBottomSheetWarning({required this.dialogWarning});

  void showModal(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      enableDrag: dialogWarning.isDismissible,
      isDismissible: dialogWarning.isDismissible,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DialogBottomSheetWarningBody(dialog: dialogWarning);
          },
        );
      },
    );
  }
}

class DialogBottomSheetWarningBody extends StatefulWidget {
  final DialogWarning dialog;
  const DialogBottomSheetWarningBody({required this.dialog, super.key});

  @override
  State<DialogBottomSheetWarningBody> createState() => _DialogBottomSheetWarningBodyState();
}

class _DialogBottomSheetWarningBodyState extends State<DialogBottomSheetWarningBody> {
  Padding getHeaderDialog() {
    return Padding(
      padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          widget.dialog.typeDialog == DialogBottomSheetType.compact
              ? Flexible(child: Text(widget.dialog.title, style: Theme.of(context).textTheme.headlineSmall))
              : Container(),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: widget.dialog.onPressedIcon ?? _onUnFocusKeyboardAndPop,
            icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Padding getBodyDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appTheme = theme.extension<app_theme.ThemeExtension>();
    final isCritical = widget.dialog.statusDialog == DialogBottomSheetStatus.statusCritical;
    final statusColor = isCritical ? appTheme?.danger ?? colorScheme.error : colorScheme.primary;
    final statusBackgroundColor = isCritical
        ? Color.alphaBlend(statusColor.withValues(alpha: 0.12), colorScheme.surfaceContainerLow)
        : colorScheme.primaryContainer;

    if (widget.dialog.typeDialog == DialogBottomSheetType.compact) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            SizedBox(width: 350, child: Text(widget.dialog.description ?? kVazio)),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: statusBackgroundColor),
              child: Center(child: Icon(widget.dialog.icon, size: 32, color: statusColor)),
            ),
            const SizedBox(height: 24),
            Text(
              widget.dialog.titleOverline ?? kVazio,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: widget.dialog.titleOverline == null ? 0 : 8),
            Text(widget.dialog.title),
            const SizedBox(height: 8),
            widget.dialog.customBody != null
                ? widget.dialog.customBody!
                : SizedBox(width: 350, child: Text(widget.dialog.description ?? kVazio)),
          ],
        ),
      );
    }
  }

  Widget getButtonsDialog() {
    double widthButton;
    if (widget.dialog.typeButtonsDialog == DialogBottomSheetTypeButtons.horizontalButtons) {
      widthButton = MediaQuery.of(context).size.width / 2 - 32;
    } else {
      widthButton = widget.dialog.widthButtons;
    }
    var buttonPrimary = Button(
      width: widthButton,
      text: widget.dialog.titleButtonPrimary,
      onPressed: widget.dialog.onPressedPrimary ?? () {},
      buttonType: widget.dialog.statusDialog == DialogBottomSheetStatus.statusDefault
          ? ButtonType.primary
          : ButtonType.criticalPrimary,
      buttonSize: ButtonSize.regular,
    );
    var buttonSecondary = Button(
      width: widthButton,
      text: widget.dialog.titleButtonSecondary ?? kVazio,
      onPressed: widget.dialog.onPressedSecondary ?? () {},
      buttonType: widget.dialog.statusDialog == DialogBottomSheetStatus.statusDefault
          ? ButtonType.secondary
          : ButtonType.criticalSecondary,
      buttonSize: ButtonSize.regular,
    );
    if (widget.dialog.typeButtonsDialog == DialogBottomSheetTypeButtons.singleButton) {
      return buttonPrimary;
    } else if (widget.dialog.typeButtonsDialog == DialogBottomSheetTypeButtons.horizontalButtons) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [buttonSecondary, const SizedBox(width: 16), buttonPrimary],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [buttonSecondary, const SizedBox(height: 16), buttonPrimary],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: widget.dialog.bottomSheetListener,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          // borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[getHeaderDialog(), getBodyDialog(), const SizedBox(height: 32), getButtonsDialog()],
              ),
            ),
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
