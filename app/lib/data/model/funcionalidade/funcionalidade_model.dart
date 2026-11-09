/// Funcionalidade do app (`public.funcionalidade`), como devolvida por `GET /v1/funcionalidade`.
class FuncionalidadeModel {
  const FuncionalidadeModel({
    required this.funcId,
    required this.funcNome,
    required this.funcDescricao,
    required this.funcIcone,
    required this.funcAtivo,
    this.funcRota,
  });

  final int funcId;
  final String funcNome;
  final String funcDescricao;

  /// Chave de `IconsMap.mdiIcons`.
  final String funcIcone;

  /// `false` enquanto a funcionalidade ainda não foi liberada.
  final bool funcAtivo;

  /// Rota do go_router; nula ou vazia quando a funcionalidade não é uma tela.
  final String? funcRota;

  factory FuncionalidadeModel.fromJson(Map<String, dynamic> json) => FuncionalidadeModel(
    funcId: ((json['funcId'] ?? json['func_id']) as num).toInt(),
    funcNome: (json['funcNome'] ?? json['func_nome']) as String,
    funcDescricao: ((json['funcDescricao'] ?? json['func_descricao']) as String?) ?? '',
    funcIcone: ((json['funcIcone'] ?? json['func_icone']) as String?) ?? '',
    funcAtivo: ((json['funcAtivo'] ?? json['func_ativo']) as bool?) ?? false,
    funcRota: (json['funcRota'] ?? json['func_rota']) as String?,
  );

  Map<String, dynamic> toJson() => {
    'funcId': funcId,
    'funcNome': funcNome,
    'funcDescricao': funcDescricao,
    'funcIcone': funcIcone,
    'funcAtivo': funcAtivo,
    'funcRota': funcRota,
  };
}
