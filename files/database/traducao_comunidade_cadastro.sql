-- Traduções do cadastro de comunidades (POST, PUT e DELETE /v1/comunidade). Idempotente: só insere chaves
-- inexistentes. Complementa traducao_comunidade.sql (lista).
-- Chaves já existentes reutilizadas pelo cadastro: nome, tipo, codigo, salvar, cancelar, excluir, confirmarExclusao,
-- registroSalvo, registroExcluido, nomeObrigatorio, dadosInvalidos, error, ok.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('novaComunidade', 'Nova comunidade', 'Nueva comunidad', 'New community'),
  ('editarComunidade', 'Editar comunidade', 'Editar comunidad', 'Edit community'),
  ('denominacao', 'Denominação', 'Denominación', 'Denomination'),
  ('tipoObrigatorio', 'Informe o tipo', 'Informe el tipo', 'Select the type'),
  ('denominacaoObrigatoria', 'Informe a denominação', 'Informe la denominación', 'Select the denomination'),
  ('nomeComunidadeMuitoLongo', 'O nome deve ter até 100 caracteres', 'El nombre debe tener hasta 100 caracteres', 'The name must be up to 100 characters'),
  ('confirmarExclusaoComunidade', 'Deseja excluir esta comunidade?', '¿Desea eliminar esta comunidad?', 'Do you want to delete this community?'),
  ('acoes', 'Ações', 'Acciones', 'Actions'),
  ('editar', 'Editar', 'Editar', 'Edit')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
