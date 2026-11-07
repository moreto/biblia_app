-- Traduções do botão de orientação da tela das AppBars (OrientationButton). Idempotente: só insere chaves inexistentes.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('telaHorizontal', 'Tela horizontal', 'Pantalla horizontal', 'Landscape'),
  ('telaVertical', 'Tela vertical', 'Pantalla vertical', 'Portrait')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
