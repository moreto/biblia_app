-- Traduções da tela de logoff (LoggofView) e do botão "Sair" da dashboard. Idempotente: só insere chaves inexistentes.
-- "cancelar" também é criada em traducao_configuracao.sql; repetida aqui para o script funcionar sozinho.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('sair', 'Sair', 'Salir', 'Sign out'),
  ('encerrarSessao', 'Encerrar sessão', 'Cerrar sesión', 'End session'),
  ('desejaSairAplicacao', 'Deseja sair da aplicação?', '¿Desea salir de la aplicación?', 'Do you want to leave the app?'),
  ('cancelar', 'Cancelar', 'Cancelar', 'Cancel')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
