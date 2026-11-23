-- Traduções da tela "Histórico de leitura" (rota /historico-leitura; tela própria, não é aba; item do menu Bíblia):
-- capítulos lidos pelo usuário na versão escolhida (GET /v1/versiculo-reacao/lidos/:versaId e versões em
-- GET /v1/versao), com resumo, "Continuar leitura", filtros e grupos por dia.
-- Idempotente: só insere chaves inexistentes.
-- Chaves já existentes reutilizadas: historicoLeitura, versao, todos, versiculosLidos, nenhumaLeituraRegistrada,
-- nenhumaVersaoDisponivel (traducao_biblia_leitura.sql), semData (traducao_grupo_leitura.sql), abrirNaLeitura
-- (traducao_versiculo_indicado.sql), atualizar, tentarNovamente, voltar, ocultarAcoes, exibirAcoes,
-- registroNaoEncontrado e respostaApiInvalida.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  -- resumo
  ('capitulosConcluidos', 'capítulos concluídos', 'capítulos completados', 'chapters completed'),
  ('capitulosEmAndamento', 'capítulos em andamento', 'capítulos en curso', 'chapters in progress'),

  -- continuar leitura
  ('continuarLeitura', 'Continuar leitura', 'Continuar lectura', 'Continue reading'),

  -- filtros (o rótulo "Todos" é a chave todos)
  ('filtroConcluidos', 'Concluídos', 'Completados', 'Completed'),
  ('filtroEmAndamento', 'Em andamento', 'En curso', 'In progress'),
  ('nenhumCapituloNoFiltro', 'Nenhum capítulo neste filtro', 'Ningún capítulo en este filtro', 'No chapters in this filter'),

  -- grupos por dia (os demais dias mostram a data; "Sem data" é a chave semData)
  ('hoje', 'Hoje', 'Hoy', 'Today'),
  ('ontem', 'Ontem', 'Ayer', 'Yesterday')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);

-- Reativa as chaves reutilizadas, caso alguma tenha sido inativada.
UPDATE public.traducao
SET trad_status = true, updated_at = now()
WHERE trad_status = false
  AND trad_chave IN ('historicoLeitura', 'versao', 'todos', 'versiculosLidos', 'nenhumaLeituraRegistrada',
                     'nenhumaVersaoDisponivel', 'semData', 'abrirNaLeitura');
