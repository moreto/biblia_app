-- Traduções do card de música da dashboard (GET /v1/musica/aleatoria). Idempotente: só insere chaves inexistentes.
-- Chaves já existentes reutilizadas pelo card: tentarNovamente, respostaApiInvalida, erroApi.
-- Nomes das plataformas (Spotify, Deezer, Apple Music) são marcas e não são traduzidos.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('musica', 'Música', 'Música', 'Song'),
  ('outraMusica', 'Outra música', 'Otra canción', 'Another song'),
  ('ouvirEm', 'Ouvir em', 'Escuchar en', 'Listen on'),
  ('nenhumaMusicaCadastrada', 'Nenhuma música cadastrada', 'No hay canciones registradas', 'No songs registered'),
  ('formatoMusicaInvalido', 'Formato de música inválido', 'Formato de canción inválido', 'Invalid song format'),
  ('naoFoiPossivelAbrirLink', 'Não foi possível abrir o link', 'No se pudo abrir el enlace', 'Could not open the link')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
