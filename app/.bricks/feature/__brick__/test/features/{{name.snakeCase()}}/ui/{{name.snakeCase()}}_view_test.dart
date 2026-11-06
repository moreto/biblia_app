import 'package:app/features/{{name.snakeCase()}}/repository/{{name.snakeCase()}}_repository.dart';
import 'package:app/features/{{name.snakeCase()}}/ui/{{name.snakeCase()}}_view.dart';
import 'package:app/features/{{name.snakeCase()}}/ui/{{name.snakeCase()}}_viewmodel.dart';
import 'package:app/features/{{name.snakeCase()}}/use_case/{{name.snakeCase()}}_usecase.dart';
import 'package:app/data/healt_model.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Fake{{name.pascalCase()}}Repository implements {{name.pascalCase()}}Repository {
  @override
  Future<Result<HealtModel>> healt() async => Result.ok(
    HealtModel(name: 'test', description: '', version: '', host: '', email: ''),
  );
}

void main() {
  testWidgets('shows the {{name.titleCase()}} screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: {{name.pascalCase()}}View(
          viewModel: {{name.pascalCase()}}Viewmodel(
            useCase: {{name.pascalCase()}}UseCase(repository: _Fake{{name.pascalCase()}}Repository()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('{{name.titleCase()}}'), findsNWidgets(2));
  });
}
