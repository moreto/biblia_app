-- Funcionalidades do app (exceto Administração), agrupadas por contexto; aparecem no card da home
-- (GET /v1/funcionalidade).
-- func_icone: chave de IconsMap.mdiIcons (app/lib/config/icons_map.dart).
-- func_rota: rota do go_router (app/lib/routing/routes.dart); vazia quando a funcionalidade não é uma tela.
--
-- Idempotente, pela chave func_nome: atualiza descrição, ícone e rota das funcionalidades que já existem e insere
-- as que faltam. O func_ativo das existentes não é alterado; as novas entram com func_ativo = false ("Em breve")
-- até serem liberadas.
WITH v (ordem, func_nome, func_descricao, func_icone, func_rota) AS (
  VALUES
    -- Acesso
    (1, 'Acesso', 'Tela inicial com verificação da API e a lista de funcionalidades, login com e-mail, senha e código de 6 dígitos (OTP) e saída da sessão.', 'login', '/home'),
    (2, 'Criar Conta', 'Cadastro com e-mail e senha, com ativação da conta pelo código de 6 dígitos enviado ao e-mail.', 'account-plus-outline', '/registro'),
    (3, 'Preferências', 'Tema (claro, escuro ou automático), idioma e orientação da tela, com a escolha salva no dispositivo.', 'theme-light-dark', ''),

    -- Dashboard
    (4, 'Dashboard', 'Tela principal com o menu de navegação, o aviso de mensagens não lidas e os cards de oração, versículo e música.', 'view-dashboard', '/dashboard'),
    (5, 'Oração do Dia', 'Card com uma oração sorteada, com opção de ler mais e de sortear outra.', 'hands-pray', ''),
    (6, 'Versículo do Dia', 'Card com um versículo sorteado, com opção de sortear outro e de marcar como lido com comentário opcional.', 'book-open-page-variant', ''),
    (7, 'Música do Dia', 'Card com uma música sorteada, com artista, gênero e inspiração, que abre no Spotify, Deezer ou Apple Music.', 'music-note', ''),

    -- Bíblia
    (8, 'Leitura Biblica', 'Índice por versão e testamento com o progresso de cada livro e capítulo; leitura do capítulo com navegação, marcação de capítulo e versículo como lido, indicação de versículos com comentário para outros usuários e histórico de leitura.', 'book-open-variant', '/biblia-leitura'),
    (9, 'Renomados', 'Lista de renomados com o texto de apresentação e os versículos de cada um na versão escolhida, que abrem direto na leitura.', 'account-star-outline', '/renomado'),
    (10, 'Indicações Recebidas', 'Versículos que outros usuários indicaram a você, com o comentário de quem indicou, que abrem direto na leitura.', 'comment-quote-outline', '/versiculo-indicado'),

    -- Comunidade
    (11, 'Minhas Comunidades', 'Cadastro das suas comunidades, com tipo e denominação, endereços, contatos e usuários de cada uma.', 'account-group-outline', '/comunidade'),
    (12, 'Encontrar Comunidades', 'Busca de comunidades por estado e cidade, com membros, endereços, contatos e liderança de cada uma.', 'map-search-outline', '/comunidade-lista'),

    -- Mensagem
    (13, 'Mensagens', 'Mensagens recebidas, com filtros de caixa de entrada, não lidas e arquivadas, marcação de lida, arquivamento e envio de mensagens a outros usuários.', 'message-text-outline', '/mensagem-lista'),

    -- Dicionário
    (14, 'Dicionário', 'Busca de palavras no dicionário da língua portuguesa enquanto digita, com etimologia, acepções, rótulos de uso e remissões de cada verbete.', 'book-alphabet', '/dicionario')
),
atualizadas AS (
  UPDATE public.funcionalidade f
  SET func_descricao = v.func_descricao, func_icone = v.func_icone, func_rota = v.func_rota
  FROM v
  WHERE f.func_nome = v.func_nome
  RETURNING f.func_nome
)
INSERT INTO public.funcionalidade (func_nome, func_descricao, func_icone, func_ativo, func_rota)
SELECT v.func_nome, v.func_descricao, v.func_icone, false, v.func_rota
FROM v
WHERE NOT EXISTS (SELECT 1 FROM public.funcionalidade f WHERE f.func_nome = v.func_nome)
ORDER BY v.ordem;
