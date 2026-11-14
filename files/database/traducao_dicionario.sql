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
  ('dicionarioFonte', 'Fonte: Novo Diccionário da Língua Portuguesa, de Cândido de Figueiredo (1913)', 'Fuente: Novo Diccionário da Língua Portuguesa, de Cândido de Figueiredo (1913)', 'Source: Novo Diccionário da Língua Portuguesa, by Cândido de Figueiredo (1913)'),
  ('textoBuscaMuitoLongo', 'A busca pode ter até 64 caracteres', 'La búsqueda puede tener hasta 64 caracteres', 'The search can have up to 64 characters'),
  ('formatoDicionarioInvalido', 'Formato do dicionário inválido', 'Formato del diccionario inválido', 'Invalid dictionary format')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
