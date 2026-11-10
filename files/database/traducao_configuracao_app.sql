-- Traduções dos erros da configuração do app (GET /v1/configuracao-app), exibidos no login e no registro.
-- Idempotente: só insere chaves inexistentes. Chave já existente reutilizada: respostaApiInvalida.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('configuracaoAppInvalida', 'Configuração do app inválida. Tente novamente mais tarde', 'Configuración de la app inválida. Inténtelo de nuevo más tarde', 'Invalid app configuration. Please try again later'),
  ('formatoConfiguracaoAppInvalido', 'Formato da configuração do app inválido', 'Formato de la configuración de la app inválido', 'Invalid app configuration format')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
