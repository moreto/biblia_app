-- Traduções dos versículos de um renomado (GET /v1/versiculo-renomado/:renoId/:versaId). Idempotente: só insere
-- chaves inexistentes.
-- Chaves já existentes reutilizadas pela tela: versao, tentarNovamente, voltar, ocultarAcoes, exibirAcoes,
-- nenhumaVersaoDisponivel, respostaApiInvalida, erroApi, erroGeralApi.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('versiculosRenomado', 'Versículos do renomado', 'Versículos del renombrado', 'Verses of the renowned'),
  ('nenhumVersiculoRenomado', 'Nenhum versículo vinculado a este renomado', 'Ningún versículo vinculado a este renombrado', 'No verses linked to this renowned person'),
  ('abrirNaLeitura', 'Abrir na leitura', 'Abrir en la lectura', 'Open in reading'),
  ('formatoVersiculoRenomadoInvalido', 'Formato de versículo do renomado inválido', 'Formato de versículo del renombrado inválido', 'Invalid renowned verse format')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
