-- Traduções das mensagens de erro do pacote service (DioProvider).
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('corpoRequisicaoObrigatorio', 'O corpo da requisição é obrigatório', 'El cuerpo de la solicitud es obligatorio', 'The request body is required')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
