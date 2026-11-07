import 'package:app/data/model/healt_model.dart';
import 'package:app/features/{{name.snakeCase()}}/repository/{{name.snakeCase()}}_repository.dart';
import 'package:app/features/{{name.snakeCase()}}/ui/{{name.snakeCase()}}_view.dart';
import 'package:app/features/{{name.snakeCase()}}/ui/{{name.snakeCase()}}_viewmodel.dart';
import 'package:app/features/{{name.snakeCase()}}/use_case/{{name.snakeCase()}}_usecase.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Fake{{name.pascalCase()}}Repository implements {{name.pascalCase()}}Repository {
  @override
  Future<Result<HealtModel>> healt() async =>
      Result.ok(HealtModel(name: 'test', description: '', version: '', host: '', email: ''));
}

void main() {
  {{name.pascalCase()}}Viewmodel criarViewModel() {
    final useCase = {{name.pascalCase()}}UseCase({{name.camelCase()}}Repository: _Fake{{name.pascalCase()}}Repository());
    return {{name.pascalCase()}}Viewmodel({{name.camelCase()}}UseCase: useCase);
  }

  test('{{name.pascalCase()}}Viewmodel carrega o modelo ao ser criado', () async {
    final viewModel = criarViewModel();
    await pumpEventQueue();

    expect(viewModel.healtCommand.completed, isTrue);
    expect(viewModel.healtModel?.name, 'test');
  });

  testWidgets('mostra a tela {{name.titleCase()}}', (tester) async {
    await tester.pumpWidget(MaterialApp(home: {{name.pascalCase()}}View(viewModel: criarViewModel())));
    await tester.pumpAndSettle();

    // título da AppBar e texto do corpo
    expect(find.text('{{name.titleCase()}}'), findsNWidgets(2));
  });
}
