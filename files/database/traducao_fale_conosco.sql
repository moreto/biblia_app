-- Traduções da tela "Fale conosco" (rota /fale-conosco; tela própria, não é aba): chamados do usuário
-- (GET /v1/fale-conosco/meus e /meus/:fconId), nova mensagem (POST /v1/fale-conosco) e resposta do usuário no
-- chamado (POST /v1/fale-conosco-interacao/solicitante).
-- Idempotente: só insere chaves inexistentes (conferidas nos scripts files/database/traducao_*.sql, nos scripts da
-- API e em files/prompts/l10n.csv em 17/11/2026).
-- Chaves já existentes reutilizadas: voltar, ocultarAcoes, exibirAcoes, tentarNovamente, atualizar, fechar, enviar,
-- novaMensagem, nome, email, informeEmail, emailInvalido, dadosInvalidos, registroNaoEncontrado,
-- respostaApiInvalida, erroGeralApi, tokenInvalido, headerInvalido.
-- Os rótulos das opções das configurações (cite_valor de faleConoscoCategoria e faleConoscoStatus) também são chaves
-- de tradução e entram no fim da lista.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('faleConosco', 'Fale conosco', 'Contáctenos', 'Contact us'),
  ('faleConoscoIntro', 'Envie sua dúvida, sugestão ou problema. Você recebe um protocolo e acompanha a resposta por aqui.', 'Envíe su duda, sugerencia o problema. Recibirá un protocolo y podrá seguir la respuesta aquí.', 'Send your question, suggestion or issue. You will get a protocol number and can follow the reply here.'),
  ('nenhumChamado', 'Você ainda não enviou nenhuma mensagem', 'Aún no ha enviado ningún mensaje', 'You have not sent any messages yet'),
  ('chamadoEnviado', 'Mensagem enviada. Protocolo', 'Mensaje enviado. Protocolo', 'Message sent. Protocol'),
  ('protocolo', 'Protocolo', 'Protocolo', 'Protocol'),
  ('categoria', 'Categoria', 'Categoría', 'Category'),
  ('situacao', 'Situação', 'Estado', 'Status'),
  ('enviadoEm', 'Enviado em', 'Enviado el', 'Sent on'),
  ('fechadoEm', 'Fechado em', 'Cerrado el', 'Closed on'),
  ('aguardandoResposta', 'Aguardando resposta do atendimento', 'Esperando respuesta del soporte', 'Waiting for a reply from support'),
  ('voce', 'Você', 'Usted', 'You'),
  ('atendimento', 'Atendimento', 'Soporte', 'Support'),
  ('responder', 'Responder', 'Responder', 'Reply'),
  ('telefoneOpcional', 'Telefone (opcional)', 'Teléfono (opcional)', 'Phone (optional)'),
  ('assunto', 'Assunto', 'Asunto', 'Subject'),
  ('mensagem', 'Mensagem', 'Mensaje', 'Message'),
  ('informeNome', 'Informe o nome', 'Ingrese el nombre', 'Enter the name'),
  ('nomeMuitoLongo', 'O nome pode ter até 150 caracteres', 'El nombre puede tener hasta 150 caracteres', 'The name can have up to 150 characters'),
  ('telefoneMuitoLongo', 'O telefone pode ter até 20 caracteres', 'El teléfono puede tener hasta 20 caracteres', 'The phone can have up to 20 characters'),
  ('informeCategoria', 'Escolha a categoria', 'Elija la categoría', 'Choose the category'),
  ('informeAssunto', 'Informe o assunto', 'Ingrese el asunto', 'Enter the subject'),
  ('assuntoMuitoLongo', 'O assunto pode ter até 150 caracteres', 'El asunto puede tener hasta 150 caracteres', 'The subject can have up to 150 characters'),
  ('informeMensagem', 'Escreva a mensagem', 'Escriba el mensaje', 'Write the message'),
  ('mensagemMuitoLonga', 'A mensagem pode ter até 4000 caracteres', 'El mensaje puede tener hasta 4000 caracteres', 'The message can have up to 4000 characters'),
  ('chamadoFechado', 'Este atendimento foi encerrado e não aceita novas mensagens', 'Esta atención fue cerrada y no acepta nuevos mensajes', 'This request was closed and does not accept new messages'),
  ('chamadoFechadoAviso', 'Atendimento encerrado. Para outro assunto, envie uma nova mensagem.', 'Atención cerrada. Para otro asunto, envíe un nuevo mensaje.', 'Request closed. For another subject, send a new message.'),
  ('faleConoscoIndisponivel', 'Fale conosco indisponível no momento. Tente novamente mais tarde', 'Contáctenos no disponible en este momento. Intente de nuevo más tarde', 'Contact us is unavailable right now. Try again later'),
  ('formatoFaleConoscoInvalido', 'Formato do Fale conosco inválido', 'Formato de Contáctenos inválido', 'Invalid contact us format'),
  -- faleConoscoCategoria
  ('duvida', 'Dúvida', 'Duda', 'Question'),
  ('sugestao', 'Sugestão', 'Sugerencia', 'Suggestion'),
  ('reclamacao', 'Reclamação', 'Reclamo', 'Complaint'),
  ('erroTecnico', 'Erro técnico', 'Error técnico', 'Technical issue'),
  ('elogio', 'Elogio', 'Elogio', 'Compliment'),
  ('outros', 'Outros', 'Otros', 'Other'),
  -- faleConoscoStatus
  ('novo', 'Novo', 'Nuevo', 'New'),
  ('emAnalise', 'Em análise', 'En análisis', 'Under review'),
  ('emAtendimento', 'Em atendimento', 'En atención', 'In progress'),
  ('respondido', 'Respondido', 'Respondido', 'Answered'),
  ('fechado', 'Fechado', 'Cerrado', 'Closed')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
