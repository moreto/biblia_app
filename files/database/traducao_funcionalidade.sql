-- Traduções do card de funcionalidades da home (GET /v1/funcionalidade). Idempotente: só insere chaves inexistentes.
-- Chaves já existentes reutilizadas pelo card: tentarNovamente, respostaApiInvalida, erroApi.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('funcionalidades', 'Funcionalidades', 'Funcionalidades', 'Features'),
  ('emBreve', 'Em breve', 'Próximamente', 'Coming soon'),
  ('nenhumaFuncionalidadeCadastrada', 'Nenhuma funcionalidade cadastrada', 'No hay funcionalidades registradas', 'No features registered'),
  ('formatoFuncionalidadeInvalido', 'Formato de funcionalidade inválido', 'Formato de funcionalidad inválido', 'Invalid feature format')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
