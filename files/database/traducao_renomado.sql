-- Traduções da tela de renomados (GET /v1/renomado). Idempotente: só insere chaves inexistentes.
-- Chaves já existentes reutilizadas pela tela: atualizar, tentarNovamente, voltar, ocultarAcoes, exibirAcoes,
-- respostaApiInvalida, erroApi, erroGeralApi.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('renomados', 'Renomados', 'Renombrados', 'Renowned'),
  ('nenhumRenomadoCadastrado', 'Nenhum renomado cadastrado', 'No hay renombrados registrados', 'No renowned people registered'),
  ('formatoRenomadoInvalido', 'Formato de renomado inválido', 'Formato de renombrado inválido', 'Invalid renowned format')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
