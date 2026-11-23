-- Traduções da leitura offline da Bíblia (BibliaLeituraView: aviso de conexão, sincronização e download da versão;
-- repositories offline e VersiculoIndicacaoUsuarioUseCase). Idempotente: só insere chaves inexistentes.
-- Chaves já existentes reutilizadas: nenhumLivroDisponivel, nenhumaVersaoDisponivel.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('semConexao',
   'Sem conexão e sem conteúdo salvo no aparelho',
   'Sin conexión y sin contenido guardado en el dispositivo',
   'No connection and no content saved on this device'),
  ('semConexaoLeituraOffline',
   'Sem conexão: lendo o que está salvo no aparelho',
   'Sin conexión: leyendo lo guardado en el dispositivo',
   'Offline: reading what is saved on this device'),
  ('alteracoesSeraoSincronizadas',
   'Sem conexão. Suas marcações serão enviadas quando a conexão voltar',
   'Sin conexión. Tus marcas se enviarán cuando vuelva la conexión',
   'Offline. Your marks will be sent when the connection is back'),
  ('sincronizando', 'Sincronizando...', 'Sincronizando...', 'Syncing...'),
  ('sincronizarAgora', 'Sincronizar agora', 'Sincronizar ahora', 'Sync now'),
  ('baixarVersaoOffline', 'Baixar para ler offline', 'Descargar para leer sin conexión', 'Download to read offline'),
  ('baixandoVersao', 'Baixando a versão...', 'Descargando la versión...', 'Downloading version...'),
  ('versaoDisponivelOffline',
   'Versão disponível offline',
   'Versión disponible sin conexión',
   'Version available offline'),
  ('removerDoAparelho', 'Remover do aparelho', 'Quitar del dispositivo', 'Remove from device'),
  ('semConexaoParaBaixar',
   'Conecte-se à internet para baixar a versão',
   'Conéctate a internet para descargar la versión',
   'Connect to the internet to download the version'),
  ('indicacaoAguardandoSincronizacao',
   'Indicação ainda não sincronizada. Conecte-se para escolher quem vai recebê-la',
   'Recomendación aún no sincronizada. Conéctate para elegir quién la recibirá',
   'Recommendation not synced yet. Connect to choose who will receive it')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
