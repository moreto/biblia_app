-- Traduções da tela "Meus dados" (rota /usuario; tela própria, com as abas "Dados cadastrais", "Senha" e
-- "Configurações"): dados do cadastro inicial (GET /v1/usuario/usuario-detalhe-by-id e PUT /v1/usuario/usuario-detalhe),
-- troca de senha (PUT /v1/acesso/senha) e configurações do usuário (GET/POST/PUT /v1/usuario-configuracao).
-- Idempotente: só insere chaves inexistentes (conferidas em GET /v1/traducao em 17/11/2026).
-- Chaves já existentes reutilizadas: salvar, voltar, atualizar, tentarNovamente, ocultarAcoes, exibirAcoes, email,
-- nomeCompleto, informeNomeCompleto, nomeCompletoMaximo70, nomeUsuario, informeNomeUsuario, nomeUsuarioInvalido,
-- nomeUsuarioDuplicado, senha, senhaMinimo6, informeConfirmacaoSenha, senhasDiferentes, novaSenhaIgualAtual,
-- senhaAtualInvalida, senhaAlterada, exibirSenha, ocultarSenha, configuracoes, usuarioConfiguracaoDuplicada,
-- registroNaoEncontrado, leituraBiblica, situacao, ativo, inativo, dadosInvalidos, respostaApiInvalida,
-- erroGeralApi, tokenInvalido e headerInvalido.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  -- tela e abas
  ('meusDados', 'Meus dados', 'Mis datos', 'My data'),
  ('dadosCadastrais', 'Dados cadastrais', 'Datos de registro', 'Account details'),

  -- aba "Dados cadastrais"
  ('meusDadosIntro', 'Estes são os dados do seu cadastro. Você pode alterar o nome completo e o nome de usuário.', 'Estos son los datos de su registro. Puede cambiar el nombre completo y el nombre de usuario.', 'These are your account details. You can change your full name and username.'),
  ('emailNaoAlteravel', 'O e-mail é usado no login e não pode ser alterado', 'El correo electrónico se usa para iniciar sesión y no se puede cambiar', 'The email is used to sign in and cannot be changed'),
  ('identificadorConta', 'Identificador da conta', 'Identificador de la cuenta', 'Account ID'),
  ('dadosSalvos', 'Dados salvos', 'Datos guardados', 'Details saved'),

  -- aba "Senha"
  ('alterarSenha', 'Alterar senha', 'Cambiar contraseña', 'Change password'),
  ('alterarSenhaIntro', 'Informe a senha atual e a nova senha. Você receberá um aviso por e-mail quando a senha for alterada.', 'Ingrese la contraseña actual y la nueva. Recibirá un aviso por correo electrónico cuando se cambie la contraseña.', 'Enter your current password and the new one. You will receive an email when the password is changed.'),
  ('senhaAtual', 'Senha atual', 'Contraseña actual', 'Current password'),
  ('informeSenhaAtual', 'Informe a senha atual', 'Ingrese la contraseña actual', 'Enter your current password'),
  ('novaSenha', 'Nova senha', 'Nueva contraseña', 'New password'),
  ('informeNovaSenha', 'Informe a nova senha', 'Ingrese la nueva contraseña', 'Enter the new password'),
  ('confirmeNovaSenha', 'Confirme a nova senha', 'Confirme la nueva contraseña', 'Confirm the new password'),

  -- aba "Configurações"
  ('configuracaoPadraoAviso', 'Você ainda não salvou suas configurações. Os valores abaixo são os padrões.', 'Aún no ha guardado su configuración. Los valores a continuación son los predeterminados.', 'You have not saved your settings yet. The values below are the defaults.'),
  ('avisosPorEmail', 'Avisos por e-mail', 'Avisos por correo electrónico', 'Email notifications'),
  ('configEmailVersiculo', 'Indicações de versículo', 'Recomendaciones de versículos', 'Verse recommendations'),
  ('configEmailVersiculoDescricao', 'Receber e-mail quando alguém indicar um versículo para você', 'Recibir un correo cuando alguien le recomiende un versículo', 'Get an email when someone recommends a verse to you'),
  ('configEmailComunidade', 'Comunidades', 'Comunidades', 'Communities'),
  ('configEmailComunidadeDescricao', 'Receber e-mail quando você for adicionado a uma comunidade', 'Recibir un correo cuando lo agreguen a una comunidad', 'Get an email when you are added to a community'),
  ('configEmailLeitura', 'Leitura bíblica', 'Lectura bíblica', 'Bible reading'),
  ('configEmailLeituraDescricao', 'Receber e-mail sobre os grupos e agendas de leitura de que você participa', 'Recibir correos sobre los grupos y agendas de lectura en los que participa', 'Get emails about the reading groups and schedules you take part in'),
  ('configEmailFaleConosco', 'Fale conosco', 'Contáctenos', 'Contact us'),
  ('configEmailFaleConoscoDescricao', 'Receber e-mail quando o atendimento responder um chamado seu', 'Recibir un correo cuando el equipo de atención responda una de sus solicitudes', 'Get an email when support replies to one of your requests'),
  ('configLeituraAberto', 'Leitura aberta', 'Lectura abierta', 'Open reading'),
  ('configLeituraAbertoDescricao', 'Deixar o seu progresso de leitura visível para outros usuários', 'Dejar su progreso de lectura visible para otros usuarios', 'Make your reading progress visible to other users'),
  ('historicoGuardado', 'Histórico guardado', 'Historial guardado', 'Saved history'),
  ('configLogsAcesso', 'Registros de acesso', 'Registros de acceso', 'Access records'),
  ('configLogsAcessoDescricao', 'Quantos registros de acesso ao app ficam guardados', 'Cuántos registros de acceso a la aplicación se guardan', 'How many app access records are kept'),
  ('configLogsNotificacao', 'Notificações', 'Notificaciones', 'Notifications'),
  ('configLogsNotificacaoDescricao', 'Quantas notificações ficam guardadas', 'Cuántas notificaciones se guardan', 'How many notifications are kept'),
  ('atualizadoEm', 'Atualizado em', 'Actualizado el', 'Updated on'),
  ('descartarAlteracoes', 'Descartar alterações', 'Descartar cambios', 'Discard changes'),
  ('configuracoesSalvas', 'Configurações salvas', 'Configuración guardada', 'Settings saved'),

  -- validações e erros
  ('quantidadeInvalida', 'Quantidade inválida', 'Cantidad no válida', 'Invalid quantity'),
  ('formatoUsuarioInvalido', 'Formato dos dados do usuário inválido', 'Formato de los datos del usuario no válido', 'Invalid user data format')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
