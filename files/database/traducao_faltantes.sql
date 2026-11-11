-- Traduções que o app ou a API usam e que GET /v1/traducao não devolve (varredura em 11/11/2026 no banco de
-- desenvolvimento). Idempotente: reativa as chaves que existem inativas e insere as que não existem.
--
-- App: chaves que já constam de outros scripts desta pasta (traducao_biblia_leitura, traducao_configuracao_app,
-- traducao_orientacao e traducao_versiculo_renomado), mas não estão ativas no banco.
-- API: códigos de mensagem de biblia_api (src/commons/constants.ts e otpController) que o app traduz ao exibir
-- o erro ou o aviso devolvido; os de troca de senha ainda não têm tela no app.
UPDATE public.traducao
SET trad_status = true, updated_at = now()
WHERE trad_status = false
  AND trad_chave IN (
    'comentarIndicarVersiculo', 'versiculoIndicadoSemComentario', 'versiculoComComentario',
    'configuracaoAppInvalida', 'formatoConfiguracaoAppInvalido',
    'telaHorizontal', 'telaVertical',
    'versiculosRenomado', 'nenhumVersiculoRenomado', 'formatoVersiculoRenomadoInvalido',
    'otpRequestAccepted',
    'senhaAtualNovaSenhaObrigatorias', 'senhaAtualInvalida', 'novaSenhaIgualAtual', 'senhaAlterada',
    'codigoTrocaSenhaEnviado', 'codigoTrocaSenhaInvalido',
    'traducaoChaveDuplicada', 'renomadoPossuiVersiculos', 'versiculoRenomadoDuplicado', 'mensagemUsuarioDuplicado'
  );

INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  -- App: leitura da Bíblia (ícone de comentário e indicação do versículo)
  ('comentarIndicarVersiculo', 'Comentar e indicar versículo', 'Comentar y recomendar versículo', 'Comment on and recommend verse'),
  ('versiculoIndicadoSemComentario', 'Versículo indicado, sem comentário', 'Versículo recomendado, sin comentario', 'Verse recommended, no comment'),
  ('versiculoComComentario', 'Versículo indicado com comentário', 'Versículo recomendado con comentario', 'Verse recommended with a comment'),
  -- App: configuração carregada na abertura
  ('configuracaoAppInvalida', 'Configuração do app inválida. Tente novamente mais tarde', 'Configuración de la app inválida. Inténtelo de nuevo más tarde', 'Invalid app configuration. Please try again later'),
  ('formatoConfiguracaoAppInvalido', 'Formato da configuração do app inválido', 'Formato de la configuración de la app inválido', 'Invalid app configuration format'),
  -- App: botão de orientação da tela
  ('telaHorizontal', 'Tela horizontal', 'Pantalla horizontal', 'Landscape'),
  ('telaVertical', 'Tela vertical', 'Pantalla vertical', 'Portrait'),
  -- App: versículos do renomado
  ('versiculosRenomado', 'Versículos do renomado', 'Versículos del renombrado', 'Verses of the renowned'),
  ('nenhumVersiculoRenomado', 'Nenhum versículo vinculado a este renomado', 'Ningún versículo vinculado a este renombrado', 'No verses linked to this renowned person'),
  ('formatoVersiculoRenomadoInvalido', 'Formato de versículo do renomado inválido', 'Formato de versículo del renombrado inválido', 'Invalid renowned verse format'),

  -- API: código de acesso (OTP)
  ('otpRequestAccepted', 'Se o e-mail estiver cadastrado, enviaremos um código de acesso', 'Si el correo está registrado, enviaremos un código de acceso', 'If the email is registered, we will send an access code'),
  -- API: troca de senha
  ('senhaAtualNovaSenhaObrigatorias', 'Senha atual e nova senha são obrigatórias', 'La contraseña actual y la nueva contraseña son obligatorias', 'Current password and new password are required'),
  ('senhaAtualInvalida', 'Senha atual inválida', 'Contraseña actual inválida', 'Invalid current password'),
  ('novaSenhaIgualAtual', 'A nova senha deve ser diferente da atual', 'La nueva contraseña debe ser diferente de la actual', 'The new password must be different from the current one'),
  ('senhaAlterada', 'Senha alterada com sucesso', 'Contraseña cambiada con éxito', 'Password changed successfully'),
  ('codigoTrocaSenhaEnviado', 'Se o e-mail estiver cadastrado, enviaremos um código para trocar a senha', 'Si el correo está registrado, enviaremos un código para cambiar la contraseña', 'If the email is registered, we will send a code to change the password'),
  ('codigoTrocaSenhaInvalido', 'Código de troca de senha inválido ou expirado', 'Código de cambio de contraseña inválido o caducado', 'Invalid or expired password change code'),
  -- API: registros duplicados ou em uso
  ('traducaoChaveDuplicada', 'Já existe uma tradução com esta chave', 'Ya existe una traducción con esta clave', 'A translation with this key already exists'),
  ('renomadoPossuiVersiculos', 'Este renomado possui versículos vinculados', 'Este renombrado tiene versículos vinculados', 'This renowned person has linked verses'),
  ('versiculoRenomadoDuplicado', 'Este versículo já está vinculado ao renomado', 'Este versículo ya está vinculado al renombrado', 'This verse is already linked to the renowned person'),
  ('mensagemUsuarioDuplicado', 'Este usuário já é destinatário da mensagem', 'Este usuario ya es destinatario del mensaje', 'This user is already a recipient of the message')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
