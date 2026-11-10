-- Traduções da leitura da Bíblia (BibliaLeituraView, histórico de leitura e indicação de versículo). Idempotente: só insere chaves inexistentes.
-- Chaves já existentes reutilizadas: voltar, tentarNovamente, comentarioOpcional, comentarioMaximo500, headerInvalido, registroNaoEncontrado, respostaApiInvalida.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('leituraBiblica', 'Leitura bíblica', 'Lectura bíblica', 'Bible reading'),
  ('marcarVersiculoLido', 'Marcar versículo como lido', 'Marcar versículo como leído', 'Mark verse as read'),
  ('desmarcarVersiculoLido', 'Desmarcar versículo lido', 'Desmarcar versículo leído', 'Unmark verse as read'),
  ('emAndamento', 'em andamento', 'en curso', 'in progress'),
  ('versao', 'Versão', 'Versión', 'Version'),
  ('todos', 'Todos', 'Todos', 'All'),
  ('historicoLeitura', 'Histórico de leitura', 'Historial de lectura', 'Reading history'),
  ('capitulosLidos', 'capítulos lidos', 'capítulos leídos', 'chapters read'),
  ('versiculosLidos', 'versículos lidos', 'versículos leídos', 'verses read'),
  ('capituloLido', 'Capítulo lido', 'Capítulo leído', 'Chapter read'),
  ('marcarCapituloLido', 'Marcar capítulo como lido', 'Marcar capítulo como leído', 'Mark chapter as read'),
  ('desmarcarCapituloLido', 'Desmarcar capítulo como lido', 'Desmarcar capítulo como leído', 'Mark chapter as unread'),
  ('capituloAnterior', 'Capítulo anterior', 'Capítulo anterior', 'Previous chapter'),
  ('proximoCapitulo', 'Próximo capítulo', 'Capítulo siguiente', 'Next chapter'),
  ('nenhumLivroDisponivel', 'Nenhum livro disponível', 'Ningún libro disponible', 'No books available'),
  ('nenhumaVersaoDisponivel', 'Nenhuma versão disponível', 'Ninguna versión disponible', 'No versions available'),
  ('nenhumaLeituraRegistrada', 'Nenhuma leitura registrada', 'Ninguna lectura registrada', 'No reading recorded'),
  ('formatoLeituraInvalido', 'Formato de leitura inválido', 'Formato de lectura inválido', 'Invalid reading format'),
  ('indicacoes', 'indicações', 'recomendaciones', 'recommendations'),
  ('voceIndicou', 'Você indicou', 'Lo recomendaste', 'You recommended'),
  ('indicarVersiculo', 'Indicar versículo', 'Recomendar versículo', 'Recommend verse'),
  ('atualizarIndicacao', 'Atualizar indicação', 'Actualizar recomendación', 'Update recommendation'),
  ('removerIndicacao', 'Remover indicação', 'Quitar recomendación', 'Remove recommendation'),
  ('formatoIndicacaoInvalido', 'Formato de indicação inválido', 'Formato de recomendación inválido', 'Invalid recommendation format'),
  ('capituloMarcadoLido', 'Capítulo marcado como lido', 'Capítulo marcado como leído', 'Chapter marked as read'),
  ('capituloDesmarcadoLido', 'Capítulo desmarcado como lido', 'Capítulo desmarcado como leído', 'Chapter marked as unread'),
  ('versiculoMarcadoLido', 'Versículo marcado como lido', 'Versículo marcado como leído', 'Verse marked as read'),
  ('versiculoDesmarcadoLido', 'Versículo desmarcado como lido', 'Versículo desmarcado como leído', 'Verse marked as unread'),
  ('capituloConcluido', 'Capítulo concluído!', '¡Capítulo concluido!', 'Chapter completed!')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
