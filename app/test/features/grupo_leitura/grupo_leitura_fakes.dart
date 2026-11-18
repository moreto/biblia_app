import 'package:app/data/model/biblia/livro_model.dart';
import 'package:app/data/model/configuracao/configuracao_item_model.dart';
import 'package:app/data/model/configuracao/configuracao_model.dart';
import 'package:app/data/model/leitura/leitura_agenda_atividade_model.dart';
import 'package:app/data/model/leitura/leitura_agenda_model.dart';
import 'package:app/data/model/leitura/leitura_model.dart';
import 'package:app/data/model/leitura/leitura_participante_model.dart';
import 'package:app/data/model/usuario/usuario_resumo_model.dart';
import 'package:app/features/grupo_leitura/grupo_leitura/repository/grupo_leitura_repository.dart';
import 'package:app/features/grupo_leitura/grupo_leitura/use_case/grupo_leitura_usecase.dart';
import 'package:app/features/grupo_leitura/grupo_leitura_agenda/repository/grupo_leitura_agenda_repository.dart';
import 'package:app/features/grupo_leitura/grupo_leitura_atividade/repository/grupo_leitura_atividade_repository.dart';
import 'package:app/features/grupo_leitura/grupo_leitura_participante/repository/grupo_leitura_participante_repository.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usuário logado nos testes.
const kUsuarioLogado = 7;

/// Grupo do usuário logado e grupo de outro usuário em que ele participa.
const grupoMeu = LeituraModel(leitId: 1, leitNome: 'Plano anual', usuaId: kUsuarioLogado, leitDono: true);
const grupoOutro = LeituraModel(leitId: 2, leitNome: 'Evangelhos', usuaId: 3, leitDescricao: 'Mateus a João');

/// Grupos em memória; [erro] faz a listagem falhar.
class FakeGrupoLeituraRepository implements GrupoLeituraRepository {
  FakeGrupoLeituraRepository([List<LeituraModel> grupos = const [grupoMeu, grupoOutro]]) : registros = [...grupos];

  final List<LeituraModel> registros;
  Exception? erro;
  final incluidos = <LeituraModel>[];
  final alterados = <LeituraModel>[];
  final excluidos = <int>[];
  int _proximoId = 50;

  @override
  Future<Result<List<LeituraModel>>> grupos() async =>
      erro != null ? Result.error(erro!) : Result.ok(List.of(registros));

  @override
  Future<Result<LeituraModel>> incluir(LeituraModel grupo) async {
    incluidos.add(grupo);
    final gravado = LeituraModel(
      leitId: _proximoId++,
      leitNome: grupo.leitNome,
      leitDescricao: grupo.leitDescricao,
      usuaId: kUsuarioLogado,
      leitDono: true,
    );
    registros.add(gravado);
    return Result.ok(LeituraModel(leitId: gravado.leitId, leitNome: gravado.leitNome, usuaId: kUsuarioLogado));
  }

  @override
  Future<Result<LeituraModel>> alterar(LeituraModel grupo) async {
    alterados.add(grupo);
    return Result.ok(grupo);
  }

  @override
  Future<Result<void>> excluir(int leitId) async {
    excluidos.add(leitId);
    registros.removeWhere((g) => g.leitId == leitId);
    return const Result.ok(null);
  }
}

const ana = LeituraParticipanteModel(lparId: 10, leitId: 1, usuaId: 4, udetNome: 'Ana Souza', udetUsuario: 'ana');
const eu = LeituraParticipanteModel(lparId: 11, leitId: 2, usuaId: kUsuarioLogado, udetNome: 'Eu Mesmo');
const carla = UsuarioResumoModel(usuaId: 5, udetNome: 'Carla Dias', udetUsuario: 'carla');

/// Participantes por grupo em memória; a busca devolve [encontraveis] filtrados pelo texto.
class FakeGrupoLeituraParticipanteRepository implements GrupoLeituraParticipanteRepository {
  FakeGrupoLeituraParticipanteRepository([Map<int, List<LeituraParticipanteModel>>? porGrupo])
    : porGrupo = {
        for (final e
            in (porGrupo ??
                    {
                      1: [ana],
                      2: [eu],
                    })
                .entries)
          e.key: [...e.value],
      };

  final Map<int, List<LeituraParticipanteModel>> porGrupo;
  final encontraveis = <UsuarioResumoModel>[
    const UsuarioResumoModel(usuaId: 4, udetNome: 'Ana Souza', udetUsuario: 'ana'),
    const UsuarioResumoModel(usuaId: 3, udetNome: 'Dono Outro', udetUsuario: 'dono'),
    carla,
  ];
  final buscas = <String>[];
  final incluidos = <LeituraParticipanteModel>[];
  final excluidos = <int>[];
  int _proximoId = 60;

  @override
  Future<Result<List<LeituraParticipanteModel>>> participantes(int leitId) async =>
      Result.ok(List.of(porGrupo[leitId] ?? const []));

  @override
  Future<Result<List<UsuarioResumoModel>>> buscarUsuarios(String texto) async {
    buscas.add(texto);
    final t = texto.toLowerCase();
    return Result.ok(encontraveis.where((u) => '${u.udetNome} ${u.udetUsuario}'.toLowerCase().contains(t)).toList());
  }

  @override
  Future<Result<LeituraParticipanteModel>> incluir(LeituraParticipanteModel participante) async {
    incluidos.add(participante);
    final usuario = encontraveis.firstWhere((u) => u.usuaId == participante.usuaId);
    final gravado = LeituraParticipanteModel(
      lparId: _proximoId++,
      leitId: participante.leitId,
      usuaId: participante.usuaId,
      udetNome: usuario.udetNome,
      udetUsuario: usuario.udetUsuario,
    );
    (porGrupo[participante.leitId] ??= []).add(gravado);
    return Result.ok(LeituraParticipanteModel(lparId: gravado.lparId, leitId: gravado.leitId, usuaId: gravado.usuaId));
  }

  @override
  Future<Result<void>> excluir(int lparId) async {
    excluidos.add(lparId);
    for (final lista in porGrupo.values) {
      lista.removeWhere((p) => p.lparId == lparId);
    }
    return const Result.ok(null);
  }
}

final leituraDia1 = LeituraAgendaModel(
  lageId: 20,
  leitId: 1,
  lageTitulo: 'Gênesis 1-3',
  lageTexto: 'Criação',
  lageDataHora: DateTime(2026, 11, 20, 19, 30),
  lageRepete: 3,
  lageFimRepete: 1,
  lageLembrete: 2,
);
const leituraSemData = LeituraAgendaModel(lageId: 21, leitId: 1, lageTitulo: 'Revisão');

/// Configurações da agenda: repetição pelo código, lembrete só pelo nome (gravada sem código) e o fim da repetição.
const configuracoesAgenda = [
  ConfiguracaoModel(confId: 41, confCodigo: 'agendaRepeticao', confNome: 'Agenda - Repetição'),
  ConfiguracaoModel(confId: 42, confCodigo: 'agendaFimRepeticao', confNome: 'Agenda - Fim Repetição'),
  ConfiguracaoModel(confId: 43, confNome: 'Agenda - Lembrete'),
];

/// Itens por configuração: inativo e sem sequência para conferir o filtro e a ordem.
const itensAgenda = <int, List<ConfiguracaoItemModel>>{
  41: [
    ConfiguracaoItemModel(citeId: 1, confId: 41, citeChave: '3', citeValor: 'segunda', citeSequencia: 3),
    ConfiguracaoItemModel(citeId: 2, confId: 41, citeChave: '2', citeValor: 'diaInteiro', citeSequencia: 2),
    ConfiguracaoItemModel(citeId: 3, confId: 41, citeChave: '9', citeValor: 'antigo', citeAtivo: false),
  ],
  42: [
    ConfiguracaoItemModel(citeId: 4, confId: 42, citeChave: '1', citeValor: 'nunca', citeSequencia: 1),
    ConfiguracaoItemModel(citeId: 5, confId: 42, citeChave: '2', citeValor: 'naData', citeSequencia: 2),
  ],
  43: [
    ConfiguracaoItemModel(citeId: 6, confId: 43, citeChave: '1', citeValor: '5minutos', citeSequencia: 1),
    ConfiguracaoItemModel(citeId: 7, confId: 43, citeChave: '2', citeValor: '15minutos', citeSequencia: 2),
  ],
};

/// Agenda por grupo em memória.
class FakeGrupoLeituraAgendaRepository implements GrupoLeituraAgendaRepository {
  FakeGrupoLeituraAgendaRepository([Map<int, List<LeituraAgendaModel>>? porGrupo])
    : porGrupo = {
        for (final e
            in (porGrupo ??
                    {
                      1: [leituraSemData, leituraDia1],
                    })
                .entries)
          e.key: [...e.value],
      };

  final Map<int, List<LeituraAgendaModel>> porGrupo;
  final incluidos = <LeituraAgendaModel>[];
  final alterados = <LeituraAgendaModel>[];
  final excluidos = <int>[];
  Exception? erroConfiguracoes;
  int configuracoesConsultadas = 0;

  @override
  Future<Result<List<ConfiguracaoModel>>> configuracoes() async {
    configuracoesConsultadas++;
    final erro = erroConfiguracoes;
    return erro != null ? Result.error(erro) : const Result.ok(configuracoesAgenda);
  }

  @override
  Future<Result<List<ConfiguracaoItemModel>>> itens(int confId) async => Result.ok(itensAgenda[confId] ?? const []);

  @override
  Future<Result<List<LeituraAgendaModel>>> agenda(int leitId) async => Result.ok(List.of(porGrupo[leitId] ?? const []));

  @override
  Future<Result<LeituraAgendaModel>> incluir(LeituraAgendaModel item) async {
    incluidos.add(item);
    return Result.ok(item);
  }

  @override
  Future<Result<LeituraAgendaModel>> alterar(LeituraAgendaModel item) async {
    alterados.add(item);
    return Result.ok(item);
  }

  @override
  Future<Result<void>> excluir(int lageId) async {
    excluidos.add(lageId);
    return const Result.ok(null);
  }
}

const lerCapitulo = LeituraAgendaAtividadeModel(laatId: 30, lageId: 20, livrId: 1, laatSeq: 1, laatTexto: 'Ler');
const orar = LeituraAgendaAtividadeModel(
  laatId: 31,
  lageId: 20,
  oracId: 9,
  laatSeq: 2,
  laatTexto: 'Orar',
  laatConcluida: true,
);
const genesis = LivroModel(livrId: 1, testId: 1, livrNome: 'Gênesis', livrAbrev: 'Gn', livrCapituloCount: 50);

/// Atividades por item da agenda em memória.
class FakeGrupoLeituraAtividadeRepository implements GrupoLeituraAtividadeRepository {
  FakeGrupoLeituraAtividadeRepository([Map<int, List<LeituraAgendaAtividadeModel>>? porItem])
    : porItem = {
        for (final e
            in (porItem ??
                    {
                      20: [orar, lerCapitulo],
                    })
                .entries)
          e.key: [...e.value],
      };

  final Map<int, List<LeituraAgendaAtividadeModel>> porItem;
  final consultas = <int>[];
  final incluidos = <LeituraAgendaAtividadeModel>[];
  final alterados = <LeituraAgendaAtividadeModel>[];
  int livrosConsultados = 0;

  @override
  Future<Result<List<LeituraAgendaAtividadeModel>>> atividades(int lageId) async {
    consultas.add(lageId);
    return Result.ok(List.of(porItem[lageId] ?? const []));
  }

  @override
  Future<Result<List<LivroModel>>> livros() async {
    livrosConsultados++;
    return const Result.ok([genesis]);
  }

  @override
  Future<Result<LeituraAgendaAtividadeModel>> incluir(LeituraAgendaAtividadeModel atividade) async {
    incluidos.add(atividade);
    return Result.ok(atividade);
  }

  @override
  Future<Result<LeituraAgendaAtividadeModel>> alterar(LeituraAgendaAtividadeModel atividade) async {
    alterados.add(atividade);
    final lista = porItem[atividade.lageId]!;
    lista[lista.indexWhere((a) => a.laatId == atividade.laatId)] = atividade;
    return Result.ok(atividade);
  }

  @override
  Future<Result<void>> excluir(int laatId) async => const Result.ok(null);
}

GrupoLeituraUseCase criarGrupoLeituraUseCase([FakeGrupoLeituraRepository? repository]) => GrupoLeituraUseCase(
  grupoLeituraRepository: repository ?? FakeGrupoLeituraRepository(),
  usuarioLogado: () => kUsuarioLogado,
);

/// Carrega `AppLocalizations` sem traduções: os textos aparecem como as chaves.
class TestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const TestLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale: locale, translations: const []));

  @override
  bool shouldReload(TestLocalizationsDelegate old) => false;
}

/// Monta [child] num `Scaffold` com as traduções de teste.
Future<void> pumpTela(WidgetTester tester, Widget child, {bool scaffold = true}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
      home: scaffold ? Scaffold(body: child) : child,
    ),
  );
  await tester.pumpAndSettle();
}
