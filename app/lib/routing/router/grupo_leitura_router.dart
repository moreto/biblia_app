import 'package:go_router/go_router.dart';

import '../../config/dependencies.dart';
import '../../features/grupo_leitura/grupo_leitura/repository/grupo_leitura_repository.dart';
import '../../features/grupo_leitura/grupo_leitura/ui/grupo_leitura_view.dart';
import '../../features/grupo_leitura/grupo_leitura/ui/grupo_leitura_viewmodel.dart';
import '../../features/grupo_leitura/grupo_leitura/use_case/grupo_leitura_usecase.dart';
import '../../features/grupo_leitura/grupo_leitura_agenda/repository/grupo_leitura_agenda_repository.dart';
import '../../features/grupo_leitura/grupo_leitura_agenda/ui/grupo_leitura_agenda_viewmodel.dart';
import '../../features/grupo_leitura/grupo_leitura_agenda/use_case/grupo_leitura_agenda_usecase.dart';
import '../../features/grupo_leitura/grupo_leitura_atividade/repository/grupo_leitura_atividade_repository.dart';
import '../../features/grupo_leitura/grupo_leitura_atividade/ui/grupo_leitura_atividade_viewmodel.dart';
import '../../features/grupo_leitura/grupo_leitura_atividade/use_case/grupo_leitura_atividade_usecase.dart';
import '../../features/grupo_leitura/grupo_leitura_participante/repository/grupo_leitura_participante_repository.dart';
import '../../features/grupo_leitura/grupo_leitura_participante/ui/grupo_leitura_participante_viewmodel.dart';
import '../../features/grupo_leitura/grupo_leitura_participante/use_case/grupo_leitura_participante_usecase.dart';
import '../routes.dart';

/// Tela de grupos de leitura (`Routes.grupoLeitura`): um viewmodel por aba, todos com o mesmo
/// [GrupoLeituraUseCase] para a lista de grupos.
class GrupoLeituraRouter {
  static Set<GoRoute> get routes => {
    GoRoute(
      path: Routes.grupoLeitura,
      builder: (context, state) {
        final grupoLeituraUseCase = GrupoLeituraUseCase(grupoLeituraRepository: locator<GrupoLeituraRepository>());
        final agendaUseCase = GrupoLeituraAgendaUseCase(
          grupoLeituraAgendaRepository: locator<GrupoLeituraAgendaRepository>(),
          grupoLeituraUseCase: grupoLeituraUseCase,
        );
        return GrupoLeituraView(
          viewModel: GrupoLeituraViewmodel(grupoLeituraUseCase: grupoLeituraUseCase),
          participanteViewModel: GrupoLeituraParticipanteViewmodel(
            grupoLeituraParticipanteUseCase: GrupoLeituraParticipanteUseCase(
              grupoLeituraParticipanteRepository: locator<GrupoLeituraParticipanteRepository>(),
              grupoLeituraUseCase: grupoLeituraUseCase,
            ),
          ),
          agendaViewModel: GrupoLeituraAgendaViewmodel(grupoLeituraAgendaUseCase: agendaUseCase),
          atividadeViewModel: GrupoLeituraAtividadeViewmodel(
            grupoLeituraAtividadeUseCase: GrupoLeituraAtividadeUseCase(
              grupoLeituraAtividadeRepository: locator<GrupoLeituraAtividadeRepository>(),
              grupoLeituraAgendaUseCase: agendaUseCase,
            ),
          ),
        );
      },
    ),
  };
}
