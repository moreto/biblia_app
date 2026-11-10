-- Traduções do cadastro de endereços da comunidade selecionada (POST, PUT e DELETE /v1/comunidade-endereco,
-- GET /v1/estado e /v1/municipio/:estaId). Idempotente: só insere chaves inexistentes. Complementa
-- traducao_comunidade_endereco.sql (lista).
-- Chaves já existentes reutilizadas pelo cadastro: cep, enderecos, nenhumEnderecoCadastrado, acoes, editar, excluir,
-- salvar, cancelar, confirmarExclusao, registroSalvo, registroExcluido, dadosInvalidos, error, ok.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('comunidade', 'Comunidade', 'Comunidad', 'Community'),
  ('novoEndereco', 'Novo endereço', 'Nueva dirección', 'New address'),
  ('editarEndereco', 'Editar endereço', 'Editar dirección', 'Edit address'),
  ('confirmarExclusaoEndereco', 'Deseja excluir este endereço?', '¿Desea eliminar esta dirección?', 'Do you want to delete this address?'),
  ('logradouro', 'Logradouro', 'Calle', 'Street'),
  ('numero', 'Número', 'Número', 'Number'),
  ('complemento', 'Complemento', 'Complemento', 'Complement'),
  ('bairro', 'Bairro', 'Barrio', 'Neighborhood'),
  ('estado', 'Estado', 'Estado', 'State'),
  ('municipio', 'Município', 'Municipio', 'City'),
  ('comunidadeObrigatoria', 'Selecione a comunidade', 'Seleccione la comunidad', 'Select the community'),
  ('cepInvalido', 'Informe o CEP com 8 dígitos', 'Informe el código postal con 8 dígitos', 'Enter the 8-digit ZIP code'),
  ('logradouroObrigatorio', 'Informe o logradouro', 'Informe la calle', 'Enter the street'),
  ('numeroInvalido', 'O número deve conter apenas dígitos', 'El número debe contener solo dígitos', 'The number must contain only digits'),
  ('municipioObrigatorio', 'Selecione o estado e o município', 'Seleccione el estado y el municipio', 'Select the state and city')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
