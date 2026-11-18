-- Traduções da tela de entrada (/home). Idempotente: só insere chaves que ainda não existem.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('biblia', 'Bíblia', 'Biblia', 'Bible'),
  ('homeAntiga', 'Home antiga', 'Inicio anterior', 'Old home'),
  ('dispositivoNaoIdentificado', 'Dispositivo não identificado', 'Dispositivo no identificado', 'Device not identified'),
  ('continuarDeOndeParou', 'Continuar de onde parou', 'Continuar donde lo dejaste', 'Continue where you left off'),
  ('escolherCapitulo', 'Escolher capítulo', 'Elegir capítulo', 'Choose chapter')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
