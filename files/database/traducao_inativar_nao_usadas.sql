-- Inativa as traduções que o app não usa mais, para que GET /v1/traducao (só devolve trad_status = true) deixe de
-- retorná-las. Não apaga nada: para voltar atrás, basta trad_status = true nas mesmas chaves. Idempotente.
--
-- Como a lista foi montada (varredura em 11/11/2026, 366 chaves ativas devolvidas pela API):
-- - em uso (332, mantidas): a chave aparece como literal no código do app (app, components, commons e service; 318)
--   ou só no código da API (biblia_api/src; 14), cujos códigos de mensagem o app também traduz
--   (ex.: codigoOtpInvalido, emailJaCadastrado, erroGeralApi, unauthorized);
-- - sem uso (34, abaixo): a chave não aparece em nenhum dos dois códigos.
--
-- Antes de rodar em produção, confira se nenhuma dessas chaves é usada por outro cliente da mesma API.
UPDATE public.traducao
SET trad_status = false, updated_at = now()
WHERE trad_status = true
  AND trad_chave IN (
    -- Empresa e vínculo de usuário à empresa (telas que não existem no app)
    'atualizarEmpresa',
    'cadastrarEmpresa',
    'codigoEmpresa',
    'dadosEmpresa',
    'empresa',
    'empresaAtualizada',
    'empresaCadastrada',
    'falhaConsultarEmpresa',
    'informeCodigoEmpresa',
    'informeCodigoVinculo',
    'informeNomeEmpresa',
    'nenhumaEmpresaCadastrada',
    'nenhumUsuarioVinculado',
    'nomeEmpresa',
    'preenchaNomeParaCriar',
    'vinculando',
    'vincular',
    'vincularEmpresa',
    'vinculeContaEmpresa',
    'vinculoRealizado',

    -- Usuários (lista antiga)
    'atualizarUsuarios',
    'atualizeAntesCadastrar',
    'falhaCarregarUsuarios',
    'formatoUsuarioInvalido',

    -- Login e registro (textos substituídos)
    'efetueRegistro',
    'esqueceu',
    'loginPorSenha',
    'voltarEntraSenha',

    -- Busca de CEP
    'buscaCep',
    'digiteCep',

    -- Gerais
    'fonte',
    'requeridaNaoLocalizada',
    'salvando',
    'salvarAlteracoes'
  );
