import 'package:commons/commons.dart';

import '../../../../config/device_info.dart';
import '../../../../config/ultimo_capitulo_preferencia.dart';
import '../../../../data/model/biblia/livro_model.dart';
import '../../../../data/model/biblia/versao_model.dart';
import '../../../biblia/biblia_leitura/use_case/biblia_leitura_usecase.dart';

/// Lê o id do aparelho; lança se a plataforma não tiver essa informação.
typedef LerIdDispositivo = Future<String> Function();

/// Dados do seletor de capítulo da home: a [versao] em que a leitura abre, os [livros] que têm capítulos nela e,
/// por `livrId`, os números dos [capitulos].
typedef SeletorCapitulo = ({VersaoModel versao, List<LivroModel> livros, Map<int, List<int>> capitulos});

Future<String> _idDoAparelho() async {
  final info = DeviceInfo.instance;
  await info.initialize();
  return info.deviceId;
}

/// Regras da tela de entrada:
/// - "Continuar de onde parou" abre o último capítulo aberto na leitura, guardado no aparelho ([continuarLeitura]);
/// - "Escolher capítulo" lista os livros e capítulos da versão preferida ([seletorCapitulo]), só os que existem
///   no índice da versão;
/// - o id do aparelho aparece embaixo dos botões ([idDispositivo]).
class HomeUseCase {
  HomeUseCase({required this.bibliaLeituraUseCase, this.ultimoCapituloPreferencia, LerIdDispositivo? lerIdDispositivo})
    : _lerIdDispositivo = lerIdDispositivo ?? _idDoAparelho;

  /// Versões, livros e índice (os mesmos da leitura).
  final BibliaLeituraUseCase bibliaLeituraUseCase;

  /// Onde a leitura guarda o último capítulo aberto; nulo não oferece "Continuar".
  final UltimoCapituloPreferencia? ultimoCapituloPreferencia;

  final LerIdDispositivo _lerIdDispositivo;

  /// Destino de "Continuar de onde parou"; nulo se nenhum capítulo foi aberto ainda.
  LeituraDestino? continuarLeitura() {
    final ultimo = ultimoCapituloPreferencia?.ultimoCapitulo;
    if (ultimo == null) return null;
    return LeituraDestino(versaId: ultimo.versaId, livrId: ultimo.livrId, capiNumero: ultimo.capiNumero);
  }

  /// Livros e capítulos da versão em que a leitura abre (a salva ou a primeira).
  Future<Result<SeletorCapitulo>> seletorCapitulo() async {
    final versoes = await bibliaLeituraUseCase.versoes();
    final List<VersaoModel> lista;
    switch (versoes) {
      case Ok<List<VersaoModel>>(value: final value):
        lista = value;
      case Error<List<VersaoModel>>(error: final error):
        return Result.error(error);
    }

    final versao = bibliaLeituraUseCase.versaoInicial(lista);
    if (versao == null) return Result.error(HandledException(message: 'nenhumaVersaoDisponivel'));

    final (livros, indice) = await (bibliaLeituraUseCase.livros(), bibliaLeituraUseCase.indice(versao.versaId)).wait;
    switch ((livros, indice)) {
      case (Ok(value: final livros), Ok(value: final indice)):
        final capitulos = {
          for (final entrada in indice.entries)
            if (entrada.value.isNotEmpty) entrada.key: [for (final capitulo in entrada.value) capitulo.capiNumero],
        };
        return Result.ok((
          versao: versao,
          livros: [
            for (final livro in livros)
              if (capitulos.containsKey(livro.livrId)) livro,
          ],
          capitulos: capitulos,
        ));
      case (Error(error: final error), _) || (_, Error(error: final error)):
        return Result.error(error);
    }
  }

  /// Id do aparelho: Android ID no Android, `identifierForVendor` no iPhone e iPad.
  ///
  /// Na web, no desktop ou se o sistema não devolver o id, falha com `dispositivoNaoIdentificado`.
  Future<Result<String>> idDispositivo() async {
    try {
      final id = await _lerIdDispositivo();
      if (id.isEmpty) return Result.error(HandledException(message: 'dispositivoNaoIdentificado'));
      return Result.ok(id);
    } catch (error) {
      Log.print(error.toString(), name: kApp, title: 'Id do dispositivo');
      return Result.error(HandledException(message: 'dispositivoNaoIdentificado'));
    }
  }
}
