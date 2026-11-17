---
name: nova-feature
description: Passo a passo para criar uma feature ou tela nova no app Flutter da Bíblia — gerar com o brick mason `feature`, model, endpoint no ApiCore, registro no GetIt, rota, card da dashboard, script SQL de traduções, ícones MDI no IconsMap, testes e validação (format, analyze, test). Use quando o usuário pedir uma tela, feature, card de dashboard, tradução nova, ícone novo ou testes para uma feature.
---

# Nova feature

Fonte completa: `files/docs/desenvolvimento.md`. Siga também a skill `arquitetura-mvvm` para as regras de camada.

## 1. Gerar o esqueleto

```bash
cd app
mason get                       # uma vez (ou ./update.sh)
mason make feature --name nome_da_feature
```

Cria `lib/features/<nome>/{repository,use_case,ui}` e `test/features/<nome>/ui/<nome>_view_test.dart`.

## 2. Completar

1. Mover para o domínio certo (`features/<dominio>/<nome>` ou `features/dashboard/widgets/<nome>`) e ajustar imports.
2. Model em `lib/data/model/<dominio>/` com `fromJson`/`toJson`.
3. Endpoint em `ApiCore` (`commons/lib/api/api_core.dart`), normalmente `HeaderType.loggedArea`.
4. Trocar o `healt` do esqueleto pelos métodos reais; regras no use case.
5. Registrar o repository em `app/lib/config/dependencies.dart`.
6. Rota: constante em `routes.dart` + `GoRoute` no `*_router.dart` do domínio.
7. Acrescentar a tela em `files/database/funcionalidade.sql`.
8. Atualizar `files/docs/mapa.md` com a nova linha.

## Card da dashboard

Modelo: `app/lib/features/dashboard/widgets/oracao`.
- Viewmodel dispara o carregamento no construtor e mantém o último valor carregado.
- Primeiro carregamento: indicador de progresso; falha nele: mensagem + "Tentar novamente"; depois, erros em SnackBar.
- Use case converte `404 registroNaoEncontrado` em `nenhuma<X>Cadastrada`.
- Viewmodel criado em `routing/router/common_router.dart` e passado à `DashboardView`.

## Traduções

1. Chaves camelCase (`strings.translate('outraMusica')`).
2. Reaproveitar chaves de `files/prompts/l10n.csv` (`tentarNovamente`, `respostaApiInvalida`, `erroApi`...).
3. Criar `files/database/traducao_<feature>.sql` idempotente, em pt-BR, es-ES e en-US:

```sql
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('chave', 'Texto PT', 'Texto ES', 'Text EN')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
```

## Ícones

- Chave MDI em kebab-case (`music-note`), acrescentada a `app/lib/config/icons_map.dart` com comentário da tela que usa.
- Na view: `static const iconeCard = 'music-note'` e `IconsMap.mdiIcons[chave] ?? Icons.<reserva>`.
- Ícones de marca deprecated: `// ignore: deprecated_member_use`.

## Testes (sem acessar a API)

- Repository fake que implementa o contrato (ex.: `_FakeOracaoRepository` devolvendo `Result`s em ordem).
- `_TestLocalizationsDelegate`: textos aparecem como as chaves (`find.text('outraMusica')`).
- Efeitos externos por injeção (ex.: `MusicaUseCase(abrirUrl: ...)`).
- Cobrir use case, model (`fromJson`), viewmodel e view.

## Validação (em `app/`, `commons/` e `components/` conforme o que mudou)

```bash
dart format -l 120 lib test
flutter analyze
flutter test
```
