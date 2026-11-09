-- Traduções do cadastro de usuário (RegistroView, POST /v1/acesso/registro e /v1/usuario-ativacao/confirmar) e do
-- link "Criar conta" do login. Idempotente: só insere chaves inexistentes.
-- Chaves já existentes reutilizadas (l10n.csv): registro, criarConta, email, informeEmail, senha, informeSenha,
-- confirmeSenha, informeConfirmacaoSenha, emailObrigatorio, emailInvalido, emailJaCadastrado, emailSenhaObrigatorios,
-- informeCodigo6Digitos, digiteCodigoEnviado, exibirSenha, ocultarSenha, error, ok.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('naoTemConta', 'Não tem conta?', '¿No tienes cuenta?', 'Don''t have an account?'),
  ('jaTemConta', 'Já tenho conta', 'Ya tengo cuenta', 'I already have an account'),
  ('senhaMinimo6', 'A senha deve ter ao menos 6 caracteres', 'La contraseña debe tener al menos 6 caracteres', 'Password must have at least 6 characters'),
  ('senhasDiferentes', 'As senhas não conferem', 'Las contraseñas no coinciden', 'Passwords do not match'),
  ('ativarConta', 'Ativar conta', 'Activar cuenta', 'Activate account'),
  ('codigoAtivacao', 'Código de ativação', 'Código de activación', 'Activation code'),
  ('codigoAtivacaoEnviado', 'Enviamos um código de ativação para', 'Enviamos un código de activación a', 'We sent an activation code to'),
  ('codigoAtivacaoInvalido', 'Código de ativação inválido', 'Código de activación inválido', 'Invalid activation code'),
  ('usuarioAtivado', 'Conta ativada', 'Cuenta activada', 'Account activated'),
  ('contaAtivadaFacaLogin', 'Conta ativada! Faça o login', '¡Cuenta activada! Inicia sesión', 'Account activated! Please sign in'),
  ('corrigirDados', 'Corrigir dados', 'Corregir datos', 'Edit details')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
