-- Traduções da tela "Mensagens" (rota /mensagem-lista; tela própria, não é aba): mensagens recebidas pelo usuário
-- (GET /v1/mensagem-usuario/recebidas) e situação lida/arquivada (PUT /v1/mensagem-usuario).
-- Idempotente: só insere chaves inexistentes.
-- Chaves já existentes reutilizadas: sistema, acoes, atualizar, voltar, ocultarAcoes, exibirAcoes, fechar,
-- tentarNovamente, respostaApiInvalida, registroNaoEncontrado, erroGeralApi.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('mensagens', 'Mensagens', 'Mensajes', 'Messages'),
  ('caixaEntrada', 'Caixa de entrada', 'Bandeja de entrada', 'Inbox'),
  ('naoLidas', 'Não lidas', 'No leídos', 'Unread'),
  ('arquivadas', 'Arquivadas', 'Archivados', 'Archived'),
  ('arquivar', 'Arquivar', 'Archivar', 'Archive'),
  ('desarquivar', 'Desarquivar', 'Desarchivar', 'Unarchive'),
  ('marcarComoLida', 'Marcar como lida', 'Marcar como leído', 'Mark as read'),
  ('marcarComoNaoLida', 'Marcar como não lida', 'Marcar como no leído', 'Mark as unread'),
  ('nenhumaMensagemRecebida', 'Nenhuma mensagem na caixa de entrada', 'Ningún mensaje en la bandeja de entrada', 'No messages in your inbox'),
  ('nenhumaMensagemNaoLida', 'Nenhuma mensagem não lida', 'Ningún mensaje no leído', 'No unread messages'),
  ('nenhumaMensagemArquivada', 'Nenhuma mensagem arquivada', 'Ningún mensaje archivado', 'No archived messages'),
  ('de', 'De', 'De', 'From'),
  ('recebidaEm', 'Recebida em', 'Recibido el', 'Received on'),
  ('lidaEm', 'Lida em', 'Leído el', 'Read on'),
  ('suaResposta', 'Sua resposta', 'Tu respuesta', 'Your reply'),
  ('formatoMensagemInvalido', 'Formato de mensagem inválido', 'Formato de mensaje inválido', 'Invalid message format')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
