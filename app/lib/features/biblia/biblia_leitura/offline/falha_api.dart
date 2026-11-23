import 'package:commons/commons.dart';
import 'package:service/service.dart';

/// Chave do erro devolvido pelos repositories offline quando o aparelho está sem conexão e não há nada salvo.
const kSemConexao = 'semConexao';

/// Erro de "sem conexão", com o mesmo formato do `DioProvider` quando a API não responde (sem `code`).
HttpServiceException semConexao() => HttpServiceException(message: kSemConexao);

/// Mensagens da API que indicam sessão inválida ou vencida: o usuário precisa entrar de novo.
const _sessaoInvalida = {'tokenInvalido', 'headerInvalido', 'unauthorized'};

/// A API não respondeu (sem rede, timeout) ou está indisponível (5xx, 429). Leituras usam o que está salvo no
/// aparelho; gravações ficam pendentes.
bool apiInacessivel(Exception error) => switch (error) {
  HttpServiceException(message: 'cancel') => false,
  HttpServiceException(:final code) => code == null || code >= 500 || code == 429,
  // Exceções fora do padrão da API (ex.: erro de socket fora do Dio) contam como falha de rede.
  HandledException() => false,
  _ => true,
};

/// Erro em que a gravação pendente deve esperar e ser tentada de novo: API inacessível ou sessão vencida (o
/// usuário entra de novo e a fila segue). Os demais (dados recusados pela API) descartam a alteração.
bool tentarDeNovo(Exception error) =>
    apiInacessivel(error) ||
    (error is HttpServiceException &&
        (error.code == 401 || error.code == 403 || _sessaoInvalida.contains(error.message)));

/// Erro 5xx da API: a alteração é tentada de novo, mas só até um limite (pode ser um dado que a API nunca aceita).
bool erroServidor(Exception error) => error is HttpServiceException && (error.code ?? 0) >= 500;
