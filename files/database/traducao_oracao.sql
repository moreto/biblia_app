-- Traduções do card de oração da dashboard (GET /v1/oracao/aleatoria). Idempotente: só insere chaves inexistentes.
-- Chaves já existentes reutilizadas pelo card: tentarNovamente, respostaApiInvalida, erroApi.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('oracao', 'Oração', 'Oración', 'Prayer'),
  ('outraOracao', 'Outra oração', 'Otra oración', 'Another prayer'),
  ('lerMais', 'Ler mais', 'Leer más', 'Read more'),
  ('lerMenos', 'Ler menos', 'Leer menos', 'Read less'),
  ('nenhumaOracaoCadastrada', 'Nenhuma oração cadastrada', 'No hay oraciones registradas', 'No prayers registered'),
  ('formatoOracaoInvalido', 'Formato de oração inválido', 'Formato de oración inválido', 'Invalid prayer format')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
