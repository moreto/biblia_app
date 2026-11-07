-- Traduções do card de versículo aleatório da dashboard (GET /v1/versiculo/aleatorio). Idempotente: só insere chaves inexistentes.
-- Chaves já existentes reutilizadas pelo card: tentarNovamente, respostaApiInvalida, erroApi.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('versiculo', 'Versículo', 'Versículo', 'Verse'),
  ('outroVersiculo', 'Outro versículo', 'Otro versículo', 'Another verse'),
  ('nenhumVersiculoCadastrado', 'Nenhum versículo cadastrado', 'No hay versículos registrados', 'No verses registered'),
  ('formatoVersiculoInvalido', 'Formato de versículo inválido', 'Formato de versículo inválido', 'Invalid verse format')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
