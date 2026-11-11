-- Traduções da tela "Encontrar comunidades" (rota /comunidade-lista; tela própria, não é aba de /comunidade):
-- todas as comunidades por estado e cidade (GET /v1/comunidade?estaId=&muniId=, /v1/estado e /v1/municipio/:estaId),
-- e o detalhe da comunidade ao tocar no item (endereços, contatos, liderança/humanograma e membros ativos).
-- Idempotente: só insere chaves inexistentes.
-- Chaves já existentes reutilizadas: estado, municipio, atualizar, voltar, ocultarAcoes, exibirAcoes,
-- tentarNovamente, formatoComunidadeInvalido, respostaApiInvalida, erroGeralApi, fechar, cep, enderecos, contatos,
-- nenhumEnderecoCadastrado, nenhumContatoCadastrado, naoFoiPossivelAbrirLink e os rótulos dos campos de contato.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('encontrarComunidades', 'Encontrar comunidades', 'Encontrar comunidades', 'Find communities'),
  ('selecioneEstado', 'Selecione o estado para ver as comunidades', 'Seleccione el estado para ver las comunidades', 'Select the state to see the communities'),
  ('todasAsCidades', 'Todas as cidades', 'Todas las ciudades', 'All cities'),
  ('nenhumaComunidadeNoLocal', 'Nenhuma comunidade encontrada neste local', 'Ninguna comunidad encontrada en este lugar', 'No communities found in this location'),
  ('membrosAtivos', 'Membros ativos', 'Miembros activos', 'Active members'),
  ('lideranca', 'Liderança', 'Liderazgo', 'Leadership'),
  ('nenhumaLiderancaCadastrada', 'Nenhuma liderança cadastrada', 'Ningún liderazgo registrado', 'No leadership registered'),
  ('naoFoiPossivelCarregar', 'Não foi possível carregar', 'No fue posible cargar', 'Could not load')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
