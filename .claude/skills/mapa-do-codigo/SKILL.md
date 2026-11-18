---
name: mapa-do-codigo
description: Localiza no app Flutter da Bíblia a rota, a feature (view/viewmodel), o use case e os endpoints da API de cada tela. Use quando o usuário citar uma tela, rota (ex. /biblia-leitura, /comunidade, /mensagem-lista), card da dashboard ou endpoint (/v1/...) e for preciso achar o código, entender o comportamento da tela ou saber qual endpoint ela chama.
---

# Mapa do código

Fonte completa: `files/docs/mapa.md`. Leia a seção do router correspondente antes de mexer numa tela.

## Como usar

1. Identifique o grupo da rota e leia a tabela dele em `files/docs/mapa.md`:
   - `AccessRouter`: abertura (configuração), `/home` (entrada), `/home-old`, `/login`, `/registro`
   - `CommonRouter`: `/dashboard` e seus cards (oração, versículo, música), `/loggof`
   - `BibliaRouter`: `/biblia-leitura`, `/renomado`, `/versiculo-renomado/:renoId`
   - `ComunidadeRouter`: `/comunidade` (abas), `/comunidade-lista`, `/versiculo-indicado`, `/mensagem-lista`
   - Administração: `/menu`, `/configuracao`, `/log`, `/notificacao`
2. Os caminhos de feature são relativos a `app/lib/features/`.
3. Os endpoints estão no enum `ApiCore` (`commons/lib/api/api_core.dart`), com prefixo `/api`.
4. A coluna "Comportamento" descreve regras de UX que precisam ser preservadas (ex.: badge de não lidas, abas de comunidade, abertura direta num versículo por query string).

## Ao alterar uma tela

- Se o comportamento, a rota ou os endpoints mudarem, atualize a linha correspondente em `files/docs/mapa.md` no mesmo trabalho.
- Telas marcadas como **Tela separada** têm rota própria; não são abas de outra tela.
