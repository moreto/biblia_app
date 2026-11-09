-- Funcionalidades do app (exceto Administração), agrupadas por contexto.
-- func_icone: chave de IconsMap.mdiIcons (app/lib/config/icons_map.dart).
-- func_rota: rota do go_router (app/lib/routing/routes.dart); vazia quando a funcionalidade não é uma tela.

-- Acesso
INSERT INTO public.funcionalidade (func_nome, func_descricao, func_icone, func_ativo, func_rota)
VALUES('Acesso', 'Tela inicial com verificação da API, login com e-mail, senha e código de 6 dígitos (OTP) e saída da sessão.', 'login', false, '/home');
INSERT INTO public.funcionalidade (func_nome, func_descricao, func_icone, func_ativo, func_rota)
VALUES('Preferências', 'Tema (claro, escuro ou automático), idioma e orientação da tela, com a escolha salva no dispositivo.', 'theme-light-dark', false, '');

-- Dashboard
INSERT INTO public.funcionalidade (func_nome, func_descricao, func_icone, func_ativo, func_rota)
VALUES('Dashboard', 'Tela principal com o menu de navegação e os cards de oração, versículo e música.', 'view-dashboard', false, '/dashboard');
INSERT INTO public.funcionalidade (func_nome, func_descricao, func_icone, func_ativo, func_rota)
VALUES('Oração do Dia', 'Card com uma oração sorteada, com opção de ler mais e de sortear outra.', 'hands-pray', false, '');
INSERT INTO public.funcionalidade (func_nome, func_descricao, func_icone, func_ativo, func_rota)
VALUES('Versículo do Dia', 'Card com um versículo sorteado, com opção de sortear outro e de marcar como lido com comentário opcional.', 'book-open-page-variant', false, '');
INSERT INTO public.funcionalidade (func_nome, func_descricao, func_icone, func_ativo, func_rota)
VALUES('Música do Dia', 'Card com uma música sorteada, com artista, gênero e inspiração, que abre no Spotify, Deezer ou Apple Music.', 'music-note', false, '');

-- Bíblia
INSERT INTO public.funcionalidade (func_nome, func_descricao, func_icone, func_ativo, func_rota)
VALUES('Leitura Biblica', 'Índice por versão e testamento com o progresso de cada livro e capítulo; leitura do capítulo com navegação, marcação de lido, indicação de versículos e histórico de leitura.', 'book-open-variant', false, '/biblia-leitura');
