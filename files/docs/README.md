# Documentação do código

Visão por camada do app Flutter. Para instalação e execução, veja o [README principal](../../README.md).

| Documento | Conteúdo |
|---|---|
| [mapa.md](./mapa.md) | Mapa rota → view/viewmodel → use case → repository → endpoint |
| [arquitetura.md](./arquitetura.md) | Camadas MVVM, fluxo de uma ação, convenções e pontos de atenção |
| [pacotes.md](./pacotes.md) | Pacotes `commons`, `service` e `components` |
| [desenvolvimento.md](./desenvolvimento.md) | Criar feature com o mason, card da dashboard, traduções, ícones e testes |

Pontos de entrada:

- [`app/lib/main.dart`](../../app/lib/main.dart): registra as dependências (`configDependencies`), carrega tema e idioma salvos (`AppConfig.load`) e chama `runApp`.
- [`app/lib/app.dart`](../../app/lib/app.dart): monta o `MaterialApp.router` com o tema de `components`, as traduções (`AppLocalizations`) e o `GoRouter`.
