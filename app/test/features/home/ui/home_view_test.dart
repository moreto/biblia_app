import 'package:app/features/home/repository/home_repository.dart';
import 'package:app/features/home/ui/home_view.dart';
import 'package:app/features/home/ui/home_viewmodel.dart';
import 'package:app/features/home/use_case/home_usecase.dart';
import 'package:app/data/healt_model.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHomeRepository implements HomeRepository {
  @override
  Future<Result<HealtModel>> healt() async => Result.ok(
    HealtModel(name: 'test', description: '', version: '', host: '', email: ''),
  );
}

void main() {
  testWidgets('shows the Home screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeView(
          viewModel: HomeViewmodel(
            useCase: HomeUseCase(repository: _FakeHomeRepository()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsNWidgets(2));
  });
}
