-- Traduções da aba "Endereços" da tela de comunidades (GET /v1/comunidade-endereco/:comuId). Idempotente: só
-- insere chaves inexistentes.
-- Chaves já existentes reutilizadas pela aba: cep, nenhumaComunidadeCadastrada, tentarNovamente, atualizar,
-- headerInvalido, respostaApiInvalida, erroApi, erroGeralApi.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('enderecos', 'Endereços', 'Direcciones', 'Addresses'),
  ('nenhumEnderecoCadastrado', 'Nenhum endereço cadastrado', 'No hay direcciones registradas', 'No addresses registered'),
  ('formatoEnderecoInvalido', 'Formato de endereço inválido', 'Formato de dirección inválido', 'Invalid address format')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
