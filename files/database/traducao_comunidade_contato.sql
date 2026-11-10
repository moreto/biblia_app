-- Traduções da aba "Contatos" da tela de comunidades (GET, POST, PUT e DELETE /v1/comunidade-contato).
-- Idempotente: só insere chaves inexistentes.
-- Chaves já existentes reutilizadas: comunidade, email, emailInvalido, comunidadeObrigatoria, acoes, editar, excluir,
-- salvar, cancelar, confirmarExclusao, registroSalvo, registroExcluido, nenhumaComunidadeCadastrada,
-- tentarNovamente, naoFoiPossivelAbrirLink, respostaApiInvalida, erroGeralApi, error, ok.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('contatos', 'Contatos', 'Contactos', 'Contacts'),
  ('nenhumContatoCadastrado', 'Nenhum contato cadastrado', 'Ningún contacto registrado', 'No contacts registered'),
  ('novoContato', 'Novo contato', 'Nuevo contacto', 'New contact'),
  ('editarContato', 'Editar contato', 'Editar contacto', 'Edit contact'),
  ('confirmarExclusaoContato', 'Deseja excluir este contato?', '¿Desea eliminar este contacto?', 'Do you want to delete this contact?'),
  ('telefonePrincipal', 'Telefone principal', 'Teléfono principal', 'Main phone'),
  ('telefoneSecundario', 'Telefone secundário', 'Teléfono secundario', 'Secondary phone'),
  ('celular', 'Celular', 'Celular', 'Mobile'),
  ('whatsapp', 'WhatsApp', 'WhatsApp', 'WhatsApp'),
  ('site', 'Site', 'Sitio web', 'Website'),
  ('facebook', 'Facebook', 'Facebook', 'Facebook'),
  ('instagram', 'Instagram', 'Instagram', 'Instagram'),
  ('youtube', 'YouTube', 'YouTube', 'YouTube'),
  ('telegram', 'Telegram', 'Telegram', 'Telegram'),
  ('contatoObrigatorio', 'Preencha pelo menos um contato', 'Complete al menos un contacto', 'Fill in at least one contact'),
  ('telefoneInvalido', 'Telefone inválido (8 a 15 dígitos)', 'Teléfono inválido (8 a 15 dígitos)', 'Invalid phone (8 to 15 digits)'),
  ('linkInvalido', 'Link ou usuário inválido (sem espaços, até 128 caracteres)', 'Enlace o usuario inválido (sin espacios, hasta 128 caracteres)', 'Invalid link or username (no spaces, up to 128 characters)'),
  ('formatoContatoInvalido', 'Formato de contato inválido', 'Formato de contacto inválido', 'Invalid contact format')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
