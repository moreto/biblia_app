-- Traduções da reação de leitura do card de versículo da dashboard (/v1/versiculo-reacao). Idempotente: só insere chaves inexistentes.
-- Chaves já existentes reutilizadas pelo card: salvar, cancelar, headerInvalido, dadosInvalidos, registroNaoEncontrado, respostaApiInvalida, erroApi.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('marcarComoLido', 'Marcar como lido', 'Marcar como leído', 'Mark as read'),
  ('desmarcarComoLido', 'Desmarcar como lido', 'Desmarcar como leído', 'Mark as unread'),
  ('formatoReacaoInvalido', 'Formato de reação inválido', 'Formato de reacción inválido', 'Invalid reaction format'),
  ('comentarioOpcional', 'Comentário (opcional)', 'Comentario (opcional)', 'Comment (optional)'),
  ('comentarioMaximo500', 'O comentário deve ter no máximo 500 caracteres', 'El comentario debe tener como máximo 500 caracteres', 'The comment must have at most 500 characters')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
