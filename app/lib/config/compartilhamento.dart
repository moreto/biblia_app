import 'package:share_plus/share_plus.dart';

/// Compartilhamento de texto pelo sistema (WhatsApp, e-mail etc.).
///
/// Abstração sobre o plugin `share_plus` para poder ser substituída nos testes.
abstract interface class Compartilhamento {
  /// Abre o compartilhamento do sistema com [texto]; [assunto] vai como assunto (ex.: no e-mail).
  Future<void> compartilhar(String texto, {String? assunto});
}

/// [Compartilhamento] com a folha de compartilhamento nativa do aparelho.
class CompartilhamentoSistema implements Compartilhamento {
  const CompartilhamentoSistema();

  @override
  Future<void> compartilhar(String texto, {String? assunto}) async {
    await SharePlus.instance.share(ShareParams(text: texto, subject: assunto));
  }
}
