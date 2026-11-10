/// Par chave/valor devolvido por `GET /v1/configuracao-app` (itens ativos da configuração `configuracaoApp`).
class ConfiguracaoAppModel {
  const ConfiguracaoAppModel({required this.citeChave, required this.citeValor});

  final String citeChave;
  final String citeValor;

  factory ConfiguracaoAppModel.fromJson(Map<String, dynamic> json) => ConfiguracaoAppModel(
    citeChave: '${json['citeChave'] ?? json['cite_chave'] ?? ''}',
    citeValor: '${json['citeValor'] ?? json['cite_valor'] ?? ''}',
  );

  Map<String, dynamic> toJson() => {'citeChave': citeChave, 'citeValor': citeValor};
}
