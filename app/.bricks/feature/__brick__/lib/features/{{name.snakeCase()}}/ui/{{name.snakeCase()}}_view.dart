import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:service/service.dart';

import '{{name.snakeCase()}}_viewmodel.dart';

class {{name.pascalCase()}}View extends StatefulWidget {
  const {{name.pascalCase()}}View({super.key, required this.viewModel});

  final {{name.pascalCase()}}Viewmodel viewModel;

  @override
  State<{{name.pascalCase()}}View> createState() => _{{name.pascalCase()}}ViewState();
}

class _{{name.pascalCase()}}ViewState extends State<{{name.pascalCase()}}View> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.healtCommand.addListener(_onResult);
  }

  @override
  void didUpdateWidget(covariant {{name.pascalCase()}}View oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.healtCommand.removeListener(_onResult);
    widget.viewModel.healtCommand.addListener(_onResult);
  }

  @override
  void dispose() {
    widget.viewModel.healtCommand.removeListener(_onResult);
    super.dispose();
  }

  void _onResult() {
    if (widget.viewModel.healtCommand.error) {
      String msgError = kDefaultAppError;

      final commandResult = widget.viewModel.healtCommand.result;
      if (commandResult case Error(error: final exception)) {
        if (exception is HandledException) {
          msgError = exception.message;
        } else if (exception is HttpServiceException) {
          msgError = exception.message ?? exception.toString();
        } else {
          msgError = exception.toString();
        }
      }

      DialogBottomSheetWarning(
        dialogWarning: DialogWarning(
          title: AppLocalizations.of(context).translate('error'),
          titleButtonPrimary: AppLocalizations.of(context).translate('ok'),
          titleButtonSecondary: AppLocalizations.of(context).translate('ok'),
          isDismissible: false,
          typeButtonsDialog: DialogBottomSheetTypeButtons.horizontalButtons,
          description: AppLocalizations.of(context).translate(msgError),
          statusDialog: DialogBottomSheetStatus.statusCritical,
          onPressedPrimary: () => context.pop(),
          onPressedSecondary: () => context.pop(),
        ),
      ).showModal(context);

      widget.viewModel.healtCommand.clearResult();
    } else if (widget.viewModel.healtCommand.completed) {
      // widget.viewModel.statusCoreBankingCommand.clearResult();
      // redirect
    }
  }

  Widget _screen() {
    if (widget.viewModel.healtCommand.running) {
      return Loading();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('{{name.titleCase()}}'), elevation: 0, centerTitle: true),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(child: Text('{{name.titleCase()}}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: widget.viewModel, builder: (context, child) => _screen());
  }
}
