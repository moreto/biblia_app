-- Traduções da tela de comunidades (GET /v1/comunidade/usuario/:usuaId, /v1/comunidade-tipo e
-- /v1/comunidade-denominacao). Idempotente: só insere chaves inexistentes.
-- Chaves já existentes reutilizadas pela tela: atualizar, tentarNovamente, voltar, ocultarAcoes, exibirAcoes,
-- headerInvalido, respostaApiInvalida, erroApi, erroGeralApi.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('comunidades', 'Comunidades', 'Comunidades', 'Communities'),
  ('minhasComunidades', 'Minhas comunidades', 'Mis comunidades', 'My communities'),
  ('nenhumaComunidadeCadastrada', 'Nenhuma comunidade cadastrada', 'No hay comunidades registradas', 'No communities registered'),
  ('formatoComunidadeInvalido', 'Formato de comunidade inválido', 'Formato de comunidad inválido', 'Invalid community format')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
