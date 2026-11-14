-- Traduções da aba "Usuários" das comunidades (rota /comunidade; GET, POST, PUT e DELETE
-- /v1/comunidade-usuario e busca em /v1/usuario/busca). Idempotente: só insere chaves inexistentes.
-- Chaves já existentes reutilizadas: usuarios, inativo, comunidade, buscarUsuario, buscarUsuarioDica,
-- nenhumUsuarioEncontrado, nenhumaComunidadeCadastrada, comunidadeObrigatoria, acoes, atualizar, voltar,
-- ocultarAcoes, exibirAcoes, tentarNovamente, confirmarExclusao, cancelar, registroSalvo, registroExcluido,
-- respostaApiInvalida, registroNaoEncontrado, error, ok.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('adicionarUsuario', 'Adicionar usuário', 'Agregar usuario', 'Add user'),
  ('nenhumUsuarioNaComunidade', 'Nenhum usuário nesta comunidade', 'Ningún usuario en esta comunidad', 'No users in this community'),
  ('ativar', 'Ativar', 'Activar', 'Activate'),
  ('desativar', 'Desativar', 'Desactivar', 'Deactivate'),
  ('remover', 'Remover', 'Quitar', 'Remove'),
  ('confirmarRemocaoUsuario', 'Deseja remover este usuário da comunidade?', '¿Desea quitar este usuario de la comunidad?', 'Do you want to remove this user from the community?'),
  ('fechar', 'Fechar', 'Cerrar', 'Close'),
  ('usuarioJaNaComunidade', 'Este usuário já está na comunidade', 'Este usuario ya está en la comunidad', 'This user is already in the community'),
  ('comunidadeUsuarioDuplicado', 'Este usuário já está na comunidade', 'Este usuario ya está en la comunidad', 'This user is already in the community'),
  ('formatoUsuarioComunidadeInvalido', 'Formato de usuário da comunidade inválido', 'Formato de usuario de la comunidad inválido', 'Invalid community user format')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
