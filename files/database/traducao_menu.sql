-- Traduções da tela de Menus (/menu). Idempotente: só insere chaves inexistentes.
-- Chaves comuns (nome, chave, sequencia, ativo, salvar, cancelar, excluir, atualizar, confirmarExclusao,
-- registroSalvo, registroExcluido, registroNaoEncontrado, nomeObrigatorio, nomeMaximo60) vêm de traducao_configuracao.sql.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('menus', 'Menus', 'Menús', 'Menus'),
  ('novoMenu', 'Novo menu', 'Nuevo menú', 'New menu'),
  ('editarMenu', 'Editar menu', 'Editar menú', 'Edit menu'),
  ('novoSubmenu', 'Novo submenu', 'Nuevo submenú', 'New submenu'),
  ('menuPai', 'Menu pai', 'Menú padre', 'Parent menu'),
  ('menuRaiz', 'Nenhum (menu principal)', 'Ninguno (menú principal)', 'None (main menu)'),
  ('icone', 'Ícone', 'Ícono', 'Icon'),
  ('iconeNaoEncontrado', 'Ícone não encontrado no app', 'Ícono no encontrado en la app', 'Icon not found in the app'),
  ('rota', 'Rota', 'Ruta', 'Route'),
  ('expandir', 'Expandir', 'Expandir', 'Expand'),
  ('recolher', 'Recolher', 'Contraer', 'Collapse'),
  ('menuInativoOculto', 'Itens inativos não aparecem na lista nem no menu do app', 'Los ítems inactivos no aparecen en la lista ni en el menú de la app', 'Inactive items are hidden from this list and from the app menu'),
  ('confirmarExclusaoMenu', 'Deseja excluir este item de menu?', '¿Desea eliminar este ítem de menú?', 'Do you want to delete this menu item?'),
  ('falhaCarregarMenus', 'Falha ao carregar os menus', 'Error al cargar los menús', 'Failed to load menus'),
  ('nenhumMenuEncontrado', 'Nenhum menu encontrado', 'No se encontró ningún menú', 'No menus found'),
  ('formatoMenuInvalido', 'Formato de menu inválido', 'Formato de menú inválido', 'Invalid menu format'),
  ('chaveObrigatoria', 'Informe a chave', 'Introduce la clave', 'Enter the key'),
  ('chaveMaximo30', 'A chave deve ter no máximo 30 caracteres', 'La clave debe tener como máximo 30 caracteres', 'Key must be at most 30 characters'),
  ('iconeMaximo90', 'O ícone deve ter no máximo 90 caracteres', 'El ícono debe tener como máximo 90 caracteres', 'Icon must be at most 90 characters'),
  ('rotaMaximo60', 'A rota deve ter no máximo 60 caracteres', 'La ruta debe tener como máximo 60 caracteres', 'Route must be at most 60 characters'),
  ('rotaInvalida', 'A rota deve começar com / e não pode ter espaços', 'La ruta debe empezar con / y no puede tener espacios', 'Route must start with / and cannot contain spaces'),
  ('menuPossuiFilhos', 'Este menu possui submenus. Exclua ou mova os submenus antes.', 'Este menú tiene submenús. Elimine o mueva los submenús antes.', 'This menu has submenus. Delete or move the submenus first.'),
  ('menuPaiInvalido', 'Menu pai inválido: o pai deve ser um menu principal e não pode ser o próprio item', 'Menú padre inválido: debe ser un menú principal y no puede ser el propio ítem', 'Invalid parent menu: it must be a main menu and cannot be the item itself')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
