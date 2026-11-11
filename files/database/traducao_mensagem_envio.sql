-- Traduções do envio de mensagem ("Nova mensagem", aberto pela tela /mensagem-lista no DialogBottomSheet):
-- GET /v1/mensagem-tipo (sem o tipo Sistema, 0), GET /v1/usuario/busca, POST /v1/mensagem e POST /v1/mensagem-usuario.
-- Idempotente: só insere chaves inexistentes. Complementa traducao_mensagem_lista.sql.
-- Chaves já existentes reutilizadas: buscarUsuario, buscarUsuarioDica, nenhumUsuarioEncontrado, remover,
-- tentarNovamente, formatoMensagemInvalido, respostaApiInvalida, erroGeralApi.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('novaMensagem', 'Nova mensagem', 'Nuevo mensaje', 'New message'),
  ('tipoMensagem', 'Tipo da mensagem', 'Tipo de mensaje', 'Message type'),
  ('destinatarios', 'Destinatários', 'Destinatarios', 'Recipients'),
  ('adicionarDestinatario', 'Adicionar destinatário', 'Agregar destinatario', 'Add recipient'),
  ('titulo', 'Título', 'Título', 'Title'),
  ('texto', 'Texto', 'Texto', 'Text'),
  ('enviar', 'Enviar', 'Enviar', 'Send'),
  ('mensagemEnviada', 'Mensagem enviada', 'Mensaje enviado', 'Message sent'),
  ('mensagemEnviadaParcialmente', 'Mensagem enviada, mas não chegou a todos os destinatários', 'Mensaje enviado, pero no llegó a todos los destinatarios', 'Message sent, but it did not reach all recipients'),
  ('tipoMensagemObrigatorio', 'Selecione o tipo da mensagem', 'Seleccione el tipo de mensaje', 'Select the message type'),
  ('destinatarioObrigatorio', 'Adicione pelo menos um destinatário', 'Agregue al menos un destinatario', 'Add at least one recipient'),
  ('tituloObrigatorio', 'Informe o título', 'Informe el título', 'Enter the title'),
  ('tituloMuitoLongo', 'O título pode ter até 100 caracteres', 'El título puede tener hasta 100 caracteres', 'The title can have up to 100 characters'),
  ('textoObrigatorio', 'Escreva a mensagem', 'Escriba el mensaje', 'Write the message'),
  ('textoMuitoLongo', 'A mensagem pode ter até 4000 caracteres', 'El mensaje puede tener hasta 4000 caracteres', 'The message can have up to 4000 characters')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
