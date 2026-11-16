-- Traduções da tela "Dicionário" (rota /dicionario; tela própria, não é aba): busca enquanto digita
-- (GET /v1/dicionario/busca) e consulta da palavra (GET /v1/dicionario/palavra/:palavra), na mesma página.
-- Idempotente: só insere chaves inexistentes (conferidas em GET /v1/traducao em 14/11/2026).
-- Chaves já existentes reutilizadas: voltar, ocultarAcoes, exibirAcoes, tentarNovamente, dadosInvalidos,
-- respostaApiInvalida, erroGeralApi, tokenInvalido, headerInvalido.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('dicionario', 'Dicionário', 'Diccionario', 'Dictionary'),
  ('buscarPalavra', 'Buscar palavra', 'Buscar palabra', 'Search word'),
  ('buscarPalavraDica', 'Digite uma palavra', 'Escriba una palabra', 'Type a word'),
  ('limpar', 'Limpar', 'Limpiar', 'Clear'),
  ('dicionarioInicio', 'Busque uma palavra para ver o significado', 'Busque una palabra para ver su significado', 'Search for a word to see its meaning'),
  ('nenhumaPalavraEncontrada', 'Nenhuma palavra encontrada', 'Ninguna palabra encontrada', 'No words found'),
  ('palavraNaoEncontrada', 'Palavra não encontrada', 'Palabra no encontrada', 'Word not found'),
  ('palavrasSemelhantes', 'Palavras semelhantes', 'Palabras similares', 'Similar words'),
  ('pronuncia', 'Pronúncia', 'Pronunciación', 'Pronunciation'),
  ('etimologia', 'Etimologia', 'Etimología', 'Etymology'),
  ('vejaTambem', 'Veja também', 'Vea también', 'See also'),
  ('dicionarioFonte', 'Fonte: Projeto Gutenberg (eBook #31552) e Dicionário Aberto. Edição digital de Rita Farinha, Alberto Manuel Brandão Simões e Online Distributed Proofreading Team (pgdp.net), a partir de imagens da Biblioteca Nacional de Portugal', 'Fuente: Proyecto Gutenberg (eBook #31552) y Dicionário Aberto. Edición digital de Rita Farinha, Alberto Manuel Brandão Simões y Online Distributed Proofreading Team (pgdp.net), a partir de imágenes de la Biblioteca Nacional de Portugal', 'Source: Project Gutenberg (eBook #31552) and Dicionário Aberto. Digital edition by Rita Farinha, Alberto Manuel Brandão Simões and the Online Distributed Proofreading Team (pgdp.net), from images provided by the National Library of Portugal'),
  ('textoBuscaMuitoLongo', 'A busca pode ter até 64 caracteres', 'La búsqueda puede tener hasta 64 caracteres', 'The search can have up to 64 characters'),
  ('formatoDicionarioInvalido', 'Formato do dicionário inválido', 'Formato del diccionario inválido', 'Invalid dictionary format')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);

-- Crédito da edição digital do dicionário importado do PDF (files/dicionario/dicionario.pdf da API, pág. 1:
-- Projeto Gutenberg eBook #31552). Atualiza a chave já cadastrada pelo INSERT acima.
UPDATE public.traducao
SET trad_pt_br = 'Fonte: Projeto Gutenberg (eBook #31552) e Dicionário Aberto. Edição digital de Rita Farinha, Alberto Manuel Brandão Simões e Online Distributed Proofreading Team (pgdp.net), a partir de imagens da Biblioteca Nacional de Portugal',
    trad_es_es = 'Fuente: Proyecto Gutenberg (eBook #31552) y Dicionário Aberto. Edición digital de Rita Farinha, Alberto Manuel Brandão Simões y Online Distributed Proofreading Team (pgdp.net), a partir de imágenes de la Biblioteca Nacional de Portugal',
    trad_en_us = 'Source: Project Gutenberg (eBook #31552) and Dicionário Aberto. Digital edition by Rita Farinha, Alberto Manuel Brandão Simões and the Online Distributed Proofreading Team (pgdp.net), from images provided by the National Library of Portugal'
WHERE trad_chave = 'dicionarioFonte';

-- Busca por voz (microfone no campo de busca do dicionário).
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('falarPalavra', 'Falar a palavra', 'Decir la palabra', 'Say the word'),
  ('pararDeOuvir', 'Parar de ouvir', 'Dejar de escuchar', 'Stop listening'),
  ('ouvindo', 'Ouvindo… fale a palavra', 'Escuchando… diga la palabra', 'Listening… say the word'),
  ('vozNaoReconhecida', 'Não foi possível entender. Tente falar novamente', 'No se pudo entender. Intente hablar de nuevo', 'Could not understand. Try speaking again'),
  ('reconhecimentoVozIndisponivel', 'Reconhecimento de voz indisponível. Verifique a permissão do microfone', 'Reconocimiento de voz no disponible. Verifique el permiso del micrófono', 'Speech recognition unavailable. Check the microphone permission')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
