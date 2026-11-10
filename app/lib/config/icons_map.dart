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
    // ...
  };
}
