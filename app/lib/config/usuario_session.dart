import '../data/model/usuario/usuario_detalhe_model.dart';

class UsuarioSession {
  UsuarioSession._();

  static final UsuarioSession instance = UsuarioSession._();

  UsuarioDetalheModel? _usuarioDetalhe;

  UsuarioDetalheModel? get usuarioDetalhe => _usuarioDetalhe;

  void setUsuarioDetalhe(UsuarioDetalheModel usuarioDetalhe) {
    _usuarioDetalhe = usuarioDetalhe;
  }

  void clear() {
    _usuarioDetalhe = null;
  }
}
