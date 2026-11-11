-- Traduções da tela "Indicações recebidas" (rota /versiculo-indicado; tela própria, não é aba): versículos que
-- outros usuários indicaram ao usuário logado (GET /v1/versiculo-indicacao-usuario/recebidas).
-- Idempotente: só insere chaves inexistentes. 'abrirNaLeitura' também está em traducao_versiculo_renomado.sql
-- (repetida aqui caso aquele script ainda não tenha sido executado).
-- Chaves já existentes reutilizadas: atualizar, voltar, ocultarAcoes, exibirAcoes, tentarNovamente,
-- formatoIndicacaoInvalido, respostaApiInvalida, erroGeralApi.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('indicacoesRecebidas', 'Indicações recebidas', 'Recomendaciones recibidas', 'Received recommendations'),
  ('nenhumaIndicacaoRecebida', 'Você ainda não recebeu indicações de leitura', 'Aún no has recibido recomendaciones de lectura', 'You have not received any reading recommendations yet'),
  ('indicadoPor', 'Indicado por', 'Recomendado por', 'Recommended by'),
  ('abrirNaLeitura', 'Abrir na leitura', 'Abrir en la lectura', 'Open in reading')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
