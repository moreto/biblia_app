import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

class IconsMap {
  static final Map<String, IconData> mdiIcons = {
    'home': MdiIcons.home,
    'cellphone-text': MdiIcons.cellphoneText,
    'factory': MdiIcons.factory,
    'message-fast-outline': MdiIcons.messageFastOutline,
    'account': MdiIcons.account,
    'account-alert': MdiIcons.accountAlert,
    'badge-account': MdiIcons.badgeAccount,
    'cog': MdiIcons.cog,
    'text-long': MdiIcons.textLong,
    'crane': MdiIcons.crane,
    'menu': MdiIcons.menu,
    // Card de versículo aleatório da dashboard (VersiculoView).
    'book-open-page-variant': MdiIcons.bookOpenPageVariant,
    'autorenew': MdiIcons.autorenew,
    'refresh': MdiIcons.refresh,
    // Reação de leitura do card de versículo (VersiculoView.iconeLido / iconeNaoLido).
    'check-circle': MdiIcons.checkCircle,
    'check-circle-outline': MdiIcons.checkCircleOutline,
    'comment-text-outline': MdiIcons.commentTextOutline,
    // Leitura: estado da indicação do versículo (BibliaLeituraView.iconeIndicadoSemComentario / iconeComentado).
    'comment-check-outline': MdiIcons.commentCheckOutline,
    'comment-text': MdiIcons.commentText,
    // Leitura da Bíblia (BibliaLeituraView.icone*); 'book-open-variant' também serve de menu_icone da leitura.
    'book-open-variant': MdiIcons.bookOpenVariant,
    'history': MdiIcons.history,
    'book-multiple': MdiIcons.bookMultiple,
    'chevron-left': MdiIcons.chevronLeft,
    'chevron-right': MdiIcons.chevronRight,
    'progress-check': MdiIcons.progressCheck,
    // Indicação de versículo (VersiculoIndicacaoSheet).
    'thumb-up': MdiIcons.thumbUp,
    'thumb-up-outline': MdiIcons.thumbUpOutline,
    'delete-outline': MdiIcons.deleteOutline,
    'book-open-variant-outline': MdiIcons.bookOpenVariantOutline,
    'book-open-page-variant-outline': MdiIcons.bookOpenPageVariantOutline,
    // Card de música da dashboard (MusicaView.icone* e MusicaPlataforma.icone);
    // 'autorenew' e 'refresh' já mapeados acima.
    'music-note': MdiIcons.musicNote,
    'account-music-outline': MdiIcons.accountMusicOutline,
    'format-quote-open': MdiIcons.formatQuoteOpen,
    // Ícones de marca: o MDI os marcou como deprecated, mas seguem no pacote 3.1.0.
    // ignore: deprecated_member_use
    'spotify': MdiIcons.spotify,
    'music-circle': MdiIcons.musicCircle,
    // ignore: deprecated_member_use
    'apple': MdiIcons.apple,
    // Funcionalidades do app (tabela funcionalidade, coluna func_icone);
    // as demais chaves usadas lá já estão mapeadas acima.
    'login': MdiIcons.login,
    'theme-light-dark': MdiIcons.themeLightDark,
    'view-dashboard': MdiIcons.viewDashboard,
    'hands-pray': MdiIcons.handsPray,
    // Card de funcionalidades da home (FuncionalidadeView.iconeCard); 'refresh' já mapeado acima.
    'apps': MdiIcons.apps,
    // Cadastro de usuário (RegistroView.icone*) e link "Criar conta" do login.
    'account-plus-outline': MdiIcons.accountPlusOutline,
    'email-outline': MdiIcons.emailOutline,
    'lock-outline': MdiIcons.lockOutline,
    'lock-check-outline': MdiIcons.lockCheckOutline,
    'eye-outline': MdiIcons.eyeOutline,
    'eye-off-outline': MdiIcons.eyeOffOutline,
    'shield-check-outline': MdiIcons.shieldCheckOutline,
    'account-outline': MdiIcons.accountOutline,
    'at': MdiIcons.at,
    // Indicação de versículo: busca de usuários para indicar (VersiculoIndicacaoSheet).
    'account-search-outline': MdiIcons.accountSearchOutline,
    // Renomados (RenomadoView.iconeRenomado); também serve de menu_icone da tela. 'refresh' já mapeado acima.
    'account-star-outline': MdiIcons.accountStarOutline,
    // Comunidades (ComunidadeView.iconeComunidade e ComunidadeAba.minhas.icone); 'account-group-outline' também
    // serve de menu_icone da tela. 'refresh' já mapeado acima.
    'church': MdiIcons.church,
    'account-group-outline': MdiIcons.accountGroupOutline,
    'account-group': MdiIcons.accountGroup,
    // Cadastro de comunidades (ComunidadeView.iconeAdicionar / iconeAcoes / iconeEditar); 'delete-outline' já
    // mapeado acima.
    'plus': MdiIcons.plus,
    'dots-vertical': MdiIcons.dotsVertical,
    'pencil-outline': MdiIcons.pencilOutline,
    // Aba e cards de endereços das comunidades (ComunidadeAba.enderecos / ComunidadeEnderecoView.iconeEndereco).
    'map-marker-outline': MdiIcons.mapMarkerOutline,
    // Aba e cards de contatos das comunidades (ComunidadeAba.contatos / ComunidadeContatoView.iconeContato) e
    // campos de contato (ContatoCampo.icone); 'email-outline' e 'thumb-up-outline' já mapeados acima. Os ícones de
    // marca do MDI estão deprecados, então as redes usam ícones genéricos: WhatsApp 'chat-outline', Facebook
    // 'thumb-up-outline', Instagram 'camera-outline', YouTube 'play-box-outline', Telegram 'send' e Discord
    // 'forum-outline'.
    'card-account-phone-outline': MdiIcons.cardAccountPhoneOutline,
    'phone-outline': MdiIcons.phoneOutline,
    'phone-classic': MdiIcons.phoneClassic,
    'cellphone': MdiIcons.cellphone,
    'chat-outline': MdiIcons.chatOutline,
    'web': MdiIcons.web,
    'camera-outline': MdiIcons.cameraOutline,
    'play-box-outline': MdiIcons.playBoxOutline,
    'send': MdiIcons.send,
    'forum-outline': MdiIcons.forumOutline,
    // Aba "Usuários" das comunidades (ComunidadeAba.usuarios / ComunidadeUsuarioView.iconeUsuarios): lista vazia, ativar,
    // desativar e remover; busca e adicionar usam 'account-search-outline' e 'account-plus-outline' (já mapeados).
    'account-multiple-outline': MdiIcons.accountMultipleOutline,
    'account-check-outline': MdiIcons.accountCheckOutline,
    'account-cancel-outline': MdiIcons.accountCancelOutline,
    'account-remove-outline': MdiIcons.accountRemoveOutline,
    // Ícones dos tipos de comunidade (biblia.comunidade_tipo.ctip_icone), usados nos cards de "Minhas comunidades"
    // (ComunidadeView.iconeDaComunidade). 'church', 'account-group', 'account-group-outline' e 'hands-pray' já
    // mapeados acima; 'cathedral' não existe no MDI (cai no ícone padrão 'church').
    'temple-hindu': MdiIcons.templeHindu,
    'church-outline': MdiIcons.churchOutline,
    'cross': MdiIcons.cross,
    'home-group': MdiIcons.homeGroup,
    'home-heart': MdiIcons.homeHeart,
    'castle': MdiIcons.castle,
    'home-city-outline': MdiIcons.homeCityOutline,
    'home-city': MdiIcons.homeCity,
    'home-outline': MdiIcons.homeOutline,
    // Tela "Encontrar comunidades" (ComunidadeListaView.iconeEncontrar; também serve de menu_icone da rota
    // /comunidade-lista). Endereço usa 'map-marker-outline' (já mapeado).
    'map-search-outline': MdiIcons.mapSearchOutline,
    // Detalhe da comunidade (ComunidadeDetalheDialog.iconeLideranca): seção de liderança (humanograma). Membros,
    // endereços e contatos usam 'account-multiple-outline', 'map-marker-outline' e 'card-account-phone-outline'.
    'sitemap-outline': MdiIcons.sitemapOutline,
    // Tela "Indicações recebidas" (VersiculoIndicadoView): comentário e data. Indicação ('thumb-up-outline', também
    // menu_icone de /versiculo-indicado), abrir na leitura ('book-open-variant') e quem indicou ('account-outline')
    // já mapeados acima.
    'comment-quote-outline': MdiIcons.commentQuoteOutline,
    'clock-outline': MdiIcons.clockOutline,
    // Tela "Mensagens" (MensagemListaView / MensagemFiltro / MensagemDetalheDialog). 'email-outline' (não lida;
    // também menu_icone de /mensagem-lista), 'dots-vertical' e 'refresh' já mapeados acima.
    'email-open-outline': MdiIcons.emailOpenOutline,
    'email-check-outline': MdiIcons.emailCheckOutline,
    'email-mark-as-unread': MdiIcons.emailMarkAsUnread,
    'bell-outline': MdiIcons.bellOutline,
    'inbox-outline': MdiIcons.inboxOutline,
    'archive-outline': MdiIcons.archiveOutline,
    'archive-arrow-up-outline': MdiIcons.archiveArrowUpOutline,
    'message-reply-text-outline': MdiIcons.messageReplyTextOutline,
    // Envio de mensagem (MensagemEnvioView): botão "Nova mensagem" e título do sheet. Enviar ('send'), buscar
    // ('account-search-outline') e adicionar destinatário ('account-plus-outline') já mapeados acima.
    'email-plus-outline': MdiIcons.emailPlusOutline,
    'account-supervisor': MdiIcons.accountSupervisor,
    'toolbox-outline': MdiIcons.toolboxOutline,
    'book-heart-outline': MdiIcons.bookHeartOutline,
    'message-text-outline': MdiIcons.messageTextOutline,
    // ...
  };
}
