import '../biblia/json_reader.dart';

/// Tipo de comunidade (`GET /v1/comunidade-tipo`).
class ComunidadeTipoModel {
  const ComunidadeTipoModel({required this.ctipId, required this.ctipNome, this.ctipIcone});

  final int ctipId;
  final String ctipNome;

  /// Ícone do tipo (`ctip_icone`): chave MDI em kebab-case de `IconsMap.mdiIcons` (ex.: `church`); nulo se não
  /// informado.
  final String? ctipIcone;

  factory ComunidadeTipoModel.fromJson(Map<String, dynamic> json) => ComunidadeTipoModel(
    ctipId: JsonReader.inteiro(json, 'ctipId', 'ctip_id'),
    ctipNome: JsonReader.texto(json, 'ctipNome', 'ctip_nome'),
    ctipIcone: JsonReader.textoOpcional(json, 'ctipIcone', 'ctip_icone'),
  );
}
