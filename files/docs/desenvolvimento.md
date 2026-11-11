# Desenvolvimento

## Criando uma feature com o mason

O brick [`feature`](../../app/.bricks/feature) gera o repository, o use case, o viewmodel, a view e o teste a partir de um modelo baseado em `healt`:

```bash
cd app
mason get                       # uma vez (ou ./update.sh)
mason make feature --name nome_da_feature
```

São criados `lib/features/<nome>/{repository,use_case,ui}` e `test/features/<nome>/ui/<nome>_view_test.dart`. Depois de gerar:

1. Mova a pasta para o domínio certo (ex.: `features/admin/<nome>` ou `features/dashboard/widgets/<nome>`) e ajuste os imports relativos.
2. Crie o model em `lib/data/model/<dominio>/` com `fromJson` e `toJson`.
3. Acrescente o endpoint em `ApiCore` ([`commons/lib/api/api_core.dart`](../../commons/lib/api/api_core.dart)), normalmente com `HeaderType.loggedArea`.
4. Troque o `healt` do esqueleto pelos métodos reais. As regras de negócio ficam no use case.
5. Registre o repository em [`config/dependencies.dart`](../../app/lib/config/dependencies.dart).
6. Crie a rota: constante em `routes.dart` e `GoRoute` no `*_router.dart` do domínio. Para um card da dashboard, veja a próxima seção.
7. Gere o script de traduções e mapeie os ícones (seções abaixo).

## Card da dashboard

Use [`dashboard/widgets/oracao`](../../app/lib/features/dashboard/widgets/oracao) como modelo; o card de música segue o mesmo formato.

- O viewmodel dispara o carregamento no construtor (`aleatoriaCommand.execute()`) e mantém o último valor carregado, para que um novo sorteio ou um erro não esvazie o card.
- A view mostra um indicador de progresso no primeiro carregamento. Se esse carregamento falhar, mostra a mensagem com "Tentar novamente". Depois disso, erros aparecem em SnackBar.
- O use case converte `404 registroNaoEncontrado` em uma chave específica (`nenhuma<X>Cadastrada`).
- O viewmodel é criado em [`common_router.dart`](../../app/lib/routing/router/common_router.dart) e passado como parâmetro à [`DashboardView`](../../app/lib/features/dashboard/ui/dashboard_view.dart). Ordem atual dos cards: oração, versículo, música.

## Traduções

1. Use chaves em camelCase na view e no use case (`strings.translate('outraMusica')`).
2. Procure a chave em [`files/prompts/l10n.csv`](../prompts/l10n.csv) (exportação de `public.traducao`) para reaproveitar o que já existe, como `tentarNovamente`, `respostaApiInvalida` e `erroApi`.
3. Crie `files/database/traducao_<feature>.sql` com as chaves novas em pt-BR, es-ES e en-US. O script é idempotente e só insere as chaves que ainda não existem:

```sql
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('chave', 'Texto PT', 'Texto ES', 'Text EN')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
```

Scripts existentes: `traducao_biblia_leitura`, `traducao_comunidade`, `traducao_comunidade_cadastro`, `traducao_comunidade_contato`, `traducao_comunidade_usuario`, `traducao_comunidade_endereco`, `traducao_comunidade_endereco_cadastro`, `traducao_configuracao`, `traducao_configuracao_app`, `traducao_funcionalidade`, `traducao_loggof`, `traducao_menu`, `traducao_musica`, `traducao_oracao`, `traducao_orientacao`, `traducao_registro`, `traducao_renomado`, `traducao_service`, `traducao_versiculo`, `traducao_versiculo_reacao` e `traducao_versiculo_renomado`. O `funcionalidade.sql` cria os dados da tabela de funcionalidades.

## Ícones

- Os ícones vêm do pacote `flutter_material_design_icons` (MDI). A chave é o nome do MDI em kebab-case (ex.: `music-note`).
- Acrescente cada chave nova a [`config/icons_map.dart`](../../app/lib/config/icons_map.dart), com um comentário dizendo qual tela a usa.
- Na view, declare as chaves como constantes (`static const iconeCard = 'music-note'`) e resolva com `IconsMap.mdiIcons[chave] ?? Icons.<reserva>`.
- O MDI marcou ícones de marca (ex.: `spotify`, `apple`) como deprecated. Ao usá-los, acrescente `// ignore: deprecated_member_use` na linha.
- Para um menu novo, grave a chave em `menu_icone` e garanta que ela esteja no `IconsMap`; senão, aparece `error_outline`.

## Testes

Os testes ficam em [`app/test/features/<feature>/`](../../app/test/features), [`app/test/routing/`](../../app/test/routing), [`commons/test/`](../../commons/test) (criptografia, headers e sessões) e [`components/test/`](../../components/test). Nenhum acessa a API:

- O repository é trocado por um fake que implementa o contrato (ex.: `_FakeOracaoRepository`, que devolve uma lista de `Result` em ordem).
- `_TestLocalizationsDelegate` carrega `AppLocalizations` sem traduções, então os textos aparecem como as chaves (`find.text('outraMusica')`).
- Efeitos externos entram por injeção. Exemplo: `MusicaUseCase(abrirUrl: ...)` substitui o `url_launcher`.
- Cubra o use case (regras e conversão de erros), o model (`fromJson`), o viewmodel (estado) e a view (renderização e interação).

Validação, em `app/`, `commons/` e `components/`:

```bash
dart format -l 120 lib test
flutter analyze
flutter test
```

## Scripts

| Script | Função |
|---|---|
| [`utils/scripts/pub_get.sh`](../../utils/scripts/pub_get.sh) | `flutter pub get` em `service`, `components`, `commons` e `app`. Com `-c` ou `--clean`, roda `flutter clean` antes. |
| [`app/update.sh`](../../app/update.sh) | Apaga os locks, roda clean e pub get em todos os pacotes, instala o mason e mostra o `dart fix --dry-run`. |
