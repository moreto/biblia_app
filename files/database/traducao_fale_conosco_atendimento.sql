-- Traduções da tela "Atendimento do Fale conosco" (rota /fale-conosco-atendimento; tela própria, não é aba; o acesso
-- será controlado pelo perfil no menu): fila (GET /v1/fale-conosco), chamado (GET/PUT/DELETE /v1/fale-conosco) e
-- interações (GET/POST /v1/fale-conosco-interacao).
-- Idempotente: só insere chaves inexistentes (conferidas nos scripts files/database/traducao_*.sql, nos scripts da
-- API e em files/prompts/l10n.csv em 17/11/2026). Rode depois de traducao_fale_conosco.sql, que tem as chaves
-- compartilhadas com a tela do solicitante.
-- Chaves já existentes reutilizadas: voltar, ocultarAcoes, exibirAcoes, tentarNovamente, atualizar, fechar, enviar,
-- excluir, cancelar, salvar, confirmarExclusao, email, site, whatsapp, registroNaoEncontrado, dadosInvalidos,
-- erroGeralApi; de traducao_fale_conosco.sql: protocolo, categoria, situacao, enviadoEm, fechadoEm, atendimento,
-- responder, informeMensagem, mensagemMuitoLonga e os rótulos de categoria e situação.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('atendimentoFaleConosco', 'Atendimento do Fale conosco', 'Atención de Contáctenos', 'Contact us support'),
  ('meusChamados', 'Meus chamados', 'Mis solicitudes', 'My requests'),
  ('todas', 'Todas', 'Todas', 'All'),
  ('nenhumChamadoNaFila', 'Nenhum chamado neste filtro', 'Ninguna solicitud en este filtro', 'No requests in this filter'),
  ('semResponsavel', 'Sem responsável', 'Sin responsable', 'Unassigned'),
  ('semResposta', 'Sem resposta', 'Sin respuesta', 'No reply'),
  ('primeiraResposta', 'Primeira resposta', 'Primera respuesta', 'First reply'),
  ('prioridade', 'Prioridade', 'Prioridad', 'Priority'),
  ('origem', 'Origem', 'Origen', 'Source'),
  ('paginaOrigem', 'Página de origem', 'Página de origen', 'Source page'),
  ('navegador', 'Navegador', 'Navegador', 'Browser'),
  ('dadosTecnicos', 'Dados técnicos', 'Datos técnicos', 'Technical data'),
  ('classificacao', 'Classificação', 'Clasificación', 'Classification'),
  ('responsavel', 'Responsável', 'Responsable', 'Assignee'),
  ('assumir', 'Assumir', 'Asumir', 'Assign to me'),
  ('liberar', 'Liberar', 'Liberar', 'Unassign'),
  ('notaInterna', 'Nota interna', 'Nota interna', 'Internal note'),
  ('notaInternaDica', 'Não é vista por quem enviou a mensagem', 'No la ve quien envió el mensaje', 'Not visible to the sender'),
  ('situacaoAposResponder', 'Situação depois de responder', 'Estado después de responder', 'Status after replying'),
  ('fecharChamado', 'Fechar chamado', 'Cerrar solicitud', 'Close request'),
  ('reabrirChamado', 'Reabrir', 'Reabrir', 'Reopen'),
  ('confirmarExclusaoChamado', 'O chamado e a conversa deixam de aparecer para o atendimento e para quem enviou.', 'La solicitud y la conversación dejan de aparecer para el soporte y para quien la envió.', 'The request and its conversation will no longer be shown to support or to the sender.'),
  ('respostaEnviada', 'Resposta enviada', 'Respuesta enviada', 'Reply sent'),
  ('notaInternaGravada', 'Nota interna gravada', 'Nota interna guardada', 'Internal note saved'),
  ('chamadoAtualizado', 'Chamado atualizado', 'Solicitud actualizada', 'Request updated'),
  ('chamadoExcluido', 'Chamado excluído', 'Solicitud eliminada', 'Request deleted'),
  ('acessoNegado', 'Acesso negado: você não tem permissão para esta tela', 'Acceso denegado: no tiene permiso para esta pantalla', 'Access denied: you do not have permission for this screen'),
  -- faleConoscoPrioridade
  ('baixa', 'Baixa', 'Baja', 'Low'),
  ('media', 'Média', 'Media', 'Medium'),
  ('alta', 'Alta', 'Alta', 'High'),
  ('urgente', 'Urgente', 'Urgente', 'Urgent'),
  -- faleConoscoOrigem (site, whatsapp e email já existem)
  ('app', 'App', 'App', 'App'),
  ('redesSociais', 'Redes sociais', 'Redes sociales', 'Social media')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);

-- acessoNegado deixou de citar administradores: atualiza a chave caso a versão anterior deste script já tenha rodado.
UPDATE public.traducao
SET trad_pt_br = 'Acesso negado: você não tem permissão para esta tela',
    trad_es_es = 'Acceso denegado: no tiene permiso para esta pantalla',
    trad_en_us = 'Access denied: you do not have permission for this screen'
WHERE trad_chave = 'acessoNegado';
