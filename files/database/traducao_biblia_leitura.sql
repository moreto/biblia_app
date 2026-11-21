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
  ('capituloConcluido', 'Capítulo concluído!', '¡Capítulo concluido!', 'Chapter completed!'),
  ('indicarPara', 'Indicar para', 'Recomendar a', 'Recommend to'),
  ('indiqueParaAdicionarUsuarios', 'Indique o versículo para poder enviá-lo a outros usuários', 'Recomienda el versículo para poder enviarlo a otros usuarios', 'Recommend the verse to be able to send it to other users'),
  ('indiqueAntesDeAdicionarUsuarios', 'Indique o versículo antes de adicionar usuários', 'Recomienda el versículo antes de agregar usuarios', 'Recommend the verse before adding users'),
  ('nenhumUsuarioIndicado', 'Nenhum usuário adicionado', 'Ningún usuario agregado', 'No users added'),
  ('buscarUsuario', 'Buscar usuário', 'Buscar usuario', 'Search user'),
  ('buscarUsuarioDica', 'Nome ou nome de usuário', 'Nombre o nombre de usuario', 'Name or username'),
  ('nenhumUsuarioEncontrado', 'Nenhum usuário encontrado', 'Ningún usuario encontrado', 'No users found'),
  ('adicionarUsuarioIndicado', 'Adicionar à indicação', 'Agregar a la recomendación', 'Add to recommendation'),
  ('removerUsuarioIndicado', 'Remover da indicação', 'Quitar de la recomendación', 'Remove from recommendation'),
  ('comentarIndicarVersiculo', 'Comentar e indicar versículo', 'Comentar y recomendar versículo', 'Comment on and recommend verse'),
  ('versiculoIndicadoSemComentario', 'Versículo indicado, sem comentário', 'Versículo recomendado, sin comentario', 'Verse recommended, no comment'),
  ('versiculoComComentario', 'Versículo indicado com comentário', 'Versículo recomendado con comentario', 'Verse recommended with a comment'),
  ('usuarioJaIndicado', 'Este usuário já recebeu a indicação', 'Este usuario ya recibió la recomendación', 'This user has already received the recommendation'),
  ('opcoesLeitura', 'Opções de leitura', 'Opciones de lectura', 'Reading options'),
  ('aoPassarPagina', 'Ao passar a página', 'Al pasar la página', 'When turning the page'),
  ('naoMarcar', 'Não marcar', 'No marcar', 'Don''t mark'),
  ('perguntar', 'Perguntar', 'Preguntar', 'Ask'),
  ('marcarLido', 'Marcar lido', 'Marcar leído', 'Mark read'),
  ('perguntaMarcarCapituloLido', 'Marcar este capítulo como lido?', '¿Marcar este capítulo como leído?', 'Mark this chapter as read?'),
  ('agoraNao', 'Agora não', 'Ahora no', 'Not now'),
  ('ouvirCapitulo', 'Ouvir o capítulo', 'Escuchar el capítulo', 'Listen to the chapter'),
  ('pararNarracao', 'Parar a narração', 'Detener la narración', 'Stop narration'),
  ('narracao', 'Narração', 'Narración', 'Narration'),
  ('voz', 'Voz', 'Voz', 'Voice'),
  ('vozQualidadeAlta', 'alta qualidade', 'alta calidad', 'high quality'),
  ('vozQualidadeNormal', 'qualidade normal', 'calidad normal', 'normal quality'),
  ('vozQualidadeBaixa', 'baixa qualidade', 'baja calidad', 'low quality'),
  ('vozOnline', 'online', 'en línea', 'online'),
  ('nenhumaVozPortugues', 'Nenhuma voz em português instalada no aparelho', 'Ninguna voz en portugués instalada en el dispositivo', 'No Portuguese voice installed on the device'),
  ('maisDevagar', 'Mais devagar', 'Más despacio', 'Slower'),
  ('maisRapido', 'Mais rápido', 'Más rápido', 'Faster'),
  ('ouvirExemplo', 'Ouvir exemplo', 'Escuchar ejemplo', 'Play sample'),
  ('narracaoContinua', 'Passar a página automaticamente', 'Pasar la página automáticamente', 'Turn the page automatically'),
  ('narracaoContinuaDica', 'Ao terminar o capítulo, continua lendo o próximo', 'Al terminar el capítulo, sigue leyendo el siguiente', 'When the chapter ends, keep reading the next one'),
  ('mostrarBarra', 'Mostrar a barra', 'Mostrar la barra', 'Show the bar'),
  ('copiar', 'Copiar', 'Copiar', 'Copy'),
  ('ouvir', 'Ouvir', 'Escuchar', 'Listen'),
  ('trechoCopiado', 'Trecho copiado', 'Fragmento copiado', 'Passage copied'),
  ('marcaTexto', 'Marca-texto', 'Resaltador', 'Highlighter'),
  ('marcaTexto_amarelo', 'Marcar de amarelo', 'Resaltar en amarillo', 'Highlight yellow'),
  ('marcaTexto_verde', 'Marcar de verde', 'Resaltar en verde', 'Highlight green'),
  ('marcaTexto_azul', 'Marcar de azul', 'Resaltar en azul', 'Highlight blue'),
  ('marcaTexto_rosa', 'Marcar de rosa', 'Resaltar en rosa', 'Highlight pink'),
  ('removerMarcaTexto', 'Remover marcação', 'Quitar resaltado', 'Remove highlight'),
  ('configuracoesLeitura', 'Configurações de leitura', 'Ajustes de lectura', 'Reading settings'),
  ('temaDoApp', 'Do app', 'De la app', 'App'),
  ('orientacaoTela', 'Orientação da tela', 'Orientación de la pantalla', 'Screen orientation'),
  ('orientacaoAutomatica', 'Automática (gira com o aparelho)', 'Automática (gira con el dispositivo)', 'Automatic (rotates with the device)'),
  ('retrato', 'Retrato (em pé)', 'Vertical', 'Portrait'),
  ('paisagem', 'Paisagem (deitada)', 'Horizontal', 'Landscape'),
  ('compartilhar', 'Compartilhar', 'Compartir', 'Share'),
  ('mensagemOpcional', 'Mensagem (opcional)', 'Mensaje (opcional)', 'Message (optional)'),
  ('dicaDitadoTeclado', 'Para falar em vez de digitar, toque no microfone do teclado', 'Para hablar en lugar de escribir, toca el micrófono del teclado', 'To speak instead of typing, tap the keyboard microphone'),
  ('ditar', 'Falar (ditado)', 'Hablar (dictado)', 'Speak (dictation)'),
  ('faleAnotacao', 'Fale a sua anotação', 'Di tu nota', 'Say your note'),
  ('corTag', 'Cor da tag', 'Color de la etiqueta', 'Tag color'),
  ('corTag_azul', 'Azul', 'Azul', 'Blue'),
  ('corTag_verde', 'Verde', 'Verde', 'Green'),
  ('corTag_amarelo', 'Amarelo', 'Amarillo', 'Yellow'),
  ('corTag_laranja', 'Laranja', 'Naranja', 'Orange'),
  ('corTag_vermelho', 'Vermelho', 'Rojo', 'Red'),
  ('corTag_rosa', 'Rosa', 'Rosa', 'Pink'),
  ('corTag_roxo', 'Roxo', 'Morado', 'Purple'),
  ('corTag_cinza', 'Cinza', 'Gris', 'Gray'),
  ('anotar', 'Anotar', 'Anotar', 'Add note'),
  ('editarAnotacao', 'Editar anotação', 'Editar nota', 'Edit note'),
  ('anotacao', 'Anotação', 'Nota', 'Note'),
  ('anotacaoSalva', 'Anotação salva', 'Nota guardada', 'Note saved'),
  ('anotacaoExcluida', 'Anotação excluída', 'Nota eliminada', 'Note deleted'),
  ('tags', 'Tags', 'Etiquetas', 'Tags'),
  ('novaTag', 'Nova tag', 'Nueva etiqueta', 'New tag'),
  ('criarTag', 'Criar tag', 'Crear etiqueta', 'Create tag'),
  ('gerenciarTags', 'Gerenciar tags', 'Gestionar etiquetas', 'Manage tags'),
  ('renomearTag', 'Renomear tag', 'Renombrar etiqueta', 'Rename tag'),
  ('excluirTag', 'Excluir tag', 'Eliminar etiqueta', 'Delete tag'),
  ('nenhumaTag', 'Nenhuma tag criada ainda', 'Aún no hay etiquetas', 'No tags yet'),
  ('tagNomeVazio', 'Digite o nome da tag', 'Escribe el nombre de la etiqueta', 'Type the tag name'),
  ('tagNomeLongo', 'Use no máximo 30 caracteres', 'Usa como máximo 30 caracteres', 'Use at most 30 characters'),
  ('tagRepetida', 'Já existe uma tag com esse nome', 'Ya existe una etiqueta con ese nombre', 'A tag with this name already exists'),
  ('entreParaConsultarDicionario', 'Entre na sua conta para consultar o dicionário', 'Inicia sesión para consultar el diccionario', 'Sign in to look up the dictionary'),
  ('tamanhoFonte', 'Tamanho da fonte', 'Tamaño de la fuente', 'Font size'),
  ('brilho', 'Brilho', 'Brillo', 'Brightness'),
  ('mostrarSetasNavegacao', 'Setas de capítulo anterior e próximo', 'Flechas de capítulo anterior y siguiente', 'Previous and next chapter arrows'),
  ('tema', 'Tema', 'Tema', 'Theme'),
  ('sistema', 'Sistema', 'Sistema', 'System'),
  ('claro', 'Claro', 'Claro', 'Light'),
  ('creme', 'Creme', 'Crema', 'Cream'),
  ('escuro', 'Escuro', 'Oscuro', 'Dark')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);

-- Configurações de leitura em grupos, escolha da versão e da voz (idioma → país → voz, com nomes amigáveis)
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us
FROM (VALUES
  ('aparencia', 'Aparência', 'Apariencia', 'Appearance'),
  ('anotacoes', 'Anotações', 'Notas', 'Notes'),
  ('versaoBiblia', 'Versão da Bíblia', 'Versión de la Biblia', 'Bible version'),
  ('velocidadeNarracao', 'Velocidade', 'Velocidad', 'Speed'),
  ('vozNarracao', 'Voz da narração', 'Voz de la narración', 'Narration voice'),
  ('vozes', 'Vozes', 'Voces', 'Voices'),
  ('nenhumaVoz', 'Nenhuma voz disponível neste aparelho', 'Ninguna voz disponible en este dispositivo', 'No voice available on this device'),
  ('ouvirVoz', 'Ouvir esta voz', 'Escuchar esta voz', 'Listen to this voice'),
  ('idioma', 'Idioma', 'Idioma', 'Language'),
  ('pais', 'País', 'País', 'Country'),
  ('paisPadrao', 'Padrão', 'Predeterminado', 'Default'),
  ('idioma_pt', 'Português', 'Portugués', 'Portuguese'),
  ('idioma_en', 'Inglês', 'Inglés', 'English'),
  ('idioma_es', 'Espanhol', 'Español', 'Spanish'),
  ('idioma_fr', 'Francês', 'Francés', 'French'),
  ('idioma_de', 'Alemão', 'Alemán', 'German'),
  ('idioma_it', 'Italiano', 'Italiano', 'Italian'),
  ('idioma_nl', 'Holandês', 'Neerlandés', 'Dutch'),
  ('idioma_pl', 'Polonês', 'Polaco', 'Polish'),
  ('idioma_ru', 'Russo', 'Ruso', 'Russian'),
  ('idioma_uk', 'Ucraniano', 'Ucraniano', 'Ukrainian'),
  ('idioma_tr', 'Turco', 'Turco', 'Turkish'),
  ('idioma_ar', 'Árabe', 'Árabe', 'Arabic'),
  ('idioma_he', 'Hebraico', 'Hebreo', 'Hebrew'),
  ('idioma_el', 'Grego', 'Griego', 'Greek'),
  ('idioma_hi', 'Hindi', 'Hindi', 'Hindi'),
  ('idioma_ja', 'Japonês', 'Japonés', 'Japanese'),
  ('idioma_ko', 'Coreano', 'Coreano', 'Korean'),
  ('idioma_zh', 'Chinês', 'Chino', 'Chinese'),
  ('idioma_id', 'Indonésio', 'Indonesio', 'Indonesian'),
  ('idioma_sv', 'Sueco', 'Sueco', 'Swedish'),
  ('pais_BR', 'Brasil', 'Brasil', 'Brazil'),
  ('pais_PT', 'Portugal', 'Portugal', 'Portugal'),
  ('pais_AO', 'Angola', 'Angola', 'Angola'),
  ('pais_MZ', 'Moçambique', 'Mozambique', 'Mozambique'),
  ('pais_US', 'Estados Unidos', 'Estados Unidos', 'United States'),
  ('pais_GB', 'Reino Unido', 'Reino Unido', 'United Kingdom'),
  ('pais_AU', 'Austrália', 'Australia', 'Australia'),
  ('pais_CA', 'Canadá', 'Canadá', 'Canada'),
  ('pais_IE', 'Irlanda', 'Irlanda', 'Ireland'),
  ('pais_IN', 'Índia', 'India', 'India'),
  ('pais_NZ', 'Nova Zelândia', 'Nueva Zelanda', 'New Zealand'),
  ('pais_ZA', 'África do Sul', 'Sudáfrica', 'South Africa'),
  ('pais_NG', 'Nigéria', 'Nigeria', 'Nigeria'),
  ('pais_ES', 'Espanha', 'España', 'Spain'),
  ('pais_MX', 'México', 'México', 'Mexico'),
  ('pais_AR', 'Argentina', 'Argentina', 'Argentina'),
  ('pais_CO', 'Colômbia', 'Colombia', 'Colombia'),
  ('pais_CL', 'Chile', 'Chile', 'Chile'),
  ('pais_PE', 'Peru', 'Perú', 'Peru'),
  ('pais_FR', 'França', 'Francia', 'France'),
  ('pais_BE', 'Bélgica', 'Bélgica', 'Belgium'),
  ('pais_CH', 'Suíça', 'Suiza', 'Switzerland'),
  ('pais_DE', 'Alemanha', 'Alemania', 'Germany'),
  ('pais_AT', 'Áustria', 'Austria', 'Austria'),
  ('pais_IT', 'Itália', 'Italia', 'Italy'),
  ('pais_NL', 'Holanda', 'Países Bajos', 'Netherlands'),
  ('pais_JP', 'Japão', 'Japón', 'Japan'),
  ('pais_KR', 'Coreia do Sul', 'Corea del Sur', 'South Korea'),
  ('pais_CN', 'China', 'China', 'China'),
  ('pais_TW', 'Taiwan', 'Taiwán', 'Taiwan'),
  ('pais_HK', 'Hong Kong', 'Hong Kong', 'Hong Kong'),
  ('pais_RU', 'Rússia', 'Rusia', 'Russia'),
  ('pais_IL', 'Israel', 'Israel', 'Israel'),
  ('pais_GR', 'Grécia', 'Grecia', 'Greece'),
  ('pais_TR', 'Turquia', 'Turquía', 'Turkey')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);

-- Configurações de leitura: restaurar o padrão
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us
FROM (VALUES
  ('restaurarPadrao', 'Restaurar padrão', 'Restablecer predeterminados', 'Restore defaults'),
  ('restaurarPadraoPergunta', 'Voltar fonte, aparência e narração ao padrão? A versão, as tags e as anotações não mudam.', '¿Volver la fuente, la apariencia y la narración a los valores predeterminados? La versión, las etiquetas y las notas no cambian.', 'Reset font, appearance and narration to defaults? Version, tags and notes stay the same.'),
  ('restaurar', 'Restaurar', 'Restablecer', 'Restore'),
  ('padraoRestaurado', 'Configurações restauradas', 'Ajustes restablecidos', 'Settings restored')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);

-- Leitura: engrenagem com as Configurações de leitura e as do app
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us
FROM (VALUES
  ('configuracoesApp', 'Configurações do app', 'Ajustes de la app', 'App settings')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);

-- Leitura: Configurações do app sem login
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us
FROM (VALUES
  ('entreParaAcessar', 'Entre para acessar', 'Inicia sesión para acceder', 'Sign in to access')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);

-- Leitura: Configurações do app sem login (sheet explicando e levando ao login)
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us
FROM (VALUES
  ('funcionalidadeRestritaLogin', 'Esta funcionalidade é restrita a quem está logado. Entre na sua conta para acessar as configurações do app.', 'Esta función está restringida a quienes han iniciado sesión. Inicia sesión para acceder a los ajustes de la app.', 'This feature is only available to signed-in users. Sign in to access the app settings.'),
  ('continuarParaLogin', 'Continuar para o login', 'Continuar al inicio de sesión', 'Continue to sign in'),
  ('voltar', 'Voltar', 'Volver', 'Back')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);

-- Leitura: trocar a versão da Bíblia só com login
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us
FROM (VALUES
  ('selecaoVersaoRestritaLogin', 'Escolher a versão da Bíblia é uma funcionalidade restrita a quem está logado. Entre na sua conta para trocar a versão.', 'Elegir la versión de la Biblia está restringido a quienes han iniciado sesión. Inicia sesión para cambiar la versión.', 'Choosing the Bible version is only available to signed-in users. Sign in to change the version.')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);

-- Configurações de leitura: cor padrão do marca-texto
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us
FROM (VALUES
  ('corMarcaTexto', 'Cor do marca-texto', 'Color del resaltador', 'Highlighter color'),
  ('cor_amarelo', 'Amarelo', 'Amarillo', 'Yellow'),
  ('cor_verde', 'Verde', 'Verde', 'Green'),
  ('cor_azul', 'Azul', 'Azul', 'Blue'),
  ('cor_rosa', 'Rosa', 'Rosa', 'Pink')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);

-- Leitura: marcar o trecho na cor escolhida nas configurações
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us
FROM (VALUES
  ('marcarTexto', 'Marcar texto', 'Resaltar texto', 'Highlight text')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);

-- Sheet do trecho: desmarcar o texto (a seleção já marca)
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us
FROM (VALUES
  ('desmarcarTexto', 'Desmarcar texto', 'Quitar resaltado', 'Remove highlight')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);

-- Tags: mais cores
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us
FROM (VALUES
  ('corTag_anil', 'Anil', 'Añil', 'Indigo'),
  ('corTag_ciano', 'Ciano', 'Cian', 'Cyan'),
  ('corTag_turquesa', 'Turquesa', 'Turquesa', 'Teal'),
  ('corTag_lima', 'Verde-limão', 'Lima', 'Lime'),
  ('corTag_ambar', 'Âmbar', 'Ámbar', 'Amber'),
  ('corTag_vinho', 'Vinho', 'Vino', 'Wine'),
  ('corTag_violeta', 'Violeta', 'Violeta', 'Violet'),
  ('corTag_marrom', 'Marrom', 'Marrón', 'Brown')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
