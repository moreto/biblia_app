-- Traduções da tela "Grupos de leitura" (rota /grupo-leitura; tela própria, com as abas "Meus grupos",
-- "Participantes", "Agenda" e "Atividades"): grupos do usuário (GET /v1/leitura e POST/PUT/DELETE /v1/leitura),
-- participantes (/v1/leitura-participante e busca em /v1/usuario/busca), agenda (/v1/leitura-agenda) e atividades
-- (/v1/leitura-agenda-atividade e livros em /v1/livro). Repetição, fim da repetição e lembrete da agenda usam os
-- itens das configurações agendaRepeticao, agendaFimRepeticao e agendaLembrete; o cite_valor de cada item é chave
-- de tradução (rótulos abaixo, os do script leitura_agenda_configuracao.sql da API). Repetição: hora, diaInteiro,
-- todosDiasSemana, sabadoDomingo, segunda a domingo, mes e ano; os rótulos antigos (naoRepete, diariamente,
-- semanalmente, mensalmente e dia, trocado por diaInteiro) são inativados em traducao_inativar_nao_usadas.sql.
-- Idempotente: só insere chaves inexistentes (conferidas em GET /v1/traducao em 18/11/2026).
-- Chaves já existentes reutilizadas: acoes, atualizar, buscarUsuario, buscarUsuarioDica, cancelar, codigo,
-- confirmarExclusao, descricao, editar, error, excluir, exibirAcoes, fechar, limpar, musica, nenhumUsuarioEncontrado,
-- nome, ocultarAcoes, ok, oracao, registroExcluido, registroSalvo, remover, tentarNovamente, texto, titulo, voce,
-- voltar, headerInvalido, registroNaoEncontrado, respostaApiInvalida, consentimentoNecessario e
-- leituraParticipanteDuplicado.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  -- tela e abas
  ('gruposLeitura', 'Grupos de leitura', 'Grupos de lectura', 'Reading groups'),
  ('meusGruposLeitura', 'Meus grupos', 'Mis grupos', 'My groups'),
  ('participantes', 'Participantes', 'Participantes', 'Participants'),
  ('agenda', 'Agenda', 'Agenda', 'Schedule'),
  ('atividades', 'Atividades', 'Actividades', 'Activities'),
  ('grupoLeitura', 'Grupo de leitura', 'Grupo de lectura', 'Reading group'),
  ('formatoGrupoLeituraInvalido', 'Os dados do grupo de leitura vieram em formato inválido', 'Los datos del grupo de lectura llegaron en un formato no válido', 'The reading group data came in an invalid format'),
  ('somenteDonoAltera', 'Só quem criou o grupo pode fazer esta alteração', 'Solo quien creó el grupo puede hacer este cambio', 'Only the group creator can make this change'),
  ('grupoLeituraObrigatorio', 'Selecione um grupo de leitura', 'Seleccione un grupo de lectura', 'Select a reading group'),

  -- aba "Meus grupos"
  ('novoGrupoLeitura', 'Novo grupo', 'Nuevo grupo', 'New group'),
  ('editarGrupoLeitura', 'Editar grupo', 'Editar grupo', 'Edit group'),
  ('nenhumGrupoLeitura', 'Você ainda não participa de nenhum grupo de leitura', 'Todavía no participa en ningún grupo de lectura', 'You are not in any reading group yet'),
  ('donoDoGrupo', 'Criado por você', 'Creado por usted', 'Created by you'),
  ('participanteDoGrupo', 'Você participa', 'Usted participa', 'You participate'),
  ('informeNomeGrupo', 'Informe o nome do grupo', 'Ingrese el nombre del grupo', 'Enter the group name'),
  ('nomeGrupoMuitoLongo', 'O nome do grupo pode ter até 256 caracteres', 'El nombre del grupo puede tener hasta 256 caracteres', 'The group name can have up to 256 characters'),
  ('descricaoGrupoMuitoLonga', 'A descrição pode ter até 512 caracteres', 'La descripción puede tener hasta 512 caracteres', 'The description can have up to 512 characters'),
  ('confirmarExclusaoGrupoLeitura', 'O grupo será excluído com a agenda, as atividades e os participantes.', 'El grupo se eliminará con la agenda, las actividades y los participantes.', 'The group will be deleted along with its schedule, activities and participants.'),

  -- aba "Participantes"
  ('adicionarParticipante', 'Adicionar participante', 'Agregar participante', 'Add participant'),
  ('nenhumParticipante', 'Nenhum participante neste grupo', 'Ningún participante en este grupo', 'No participants in this group'),
  ('usuarioJaNoGrupo', 'Este usuário já participa do grupo', 'Este usuario ya participa en el grupo', 'This user is already in the group'),
  ('confirmarRemocaoParticipante', 'O usuário deixará de participar do grupo.', 'El usuario dejará de participar en el grupo.', 'The user will no longer be part of the group.'),
  ('sairDoGrupo', 'Sair do grupo', 'Salir del grupo', 'Leave group'),
  ('confirmarSairDoGrupo', 'Você deixará de participar deste grupo.', 'Dejará de participar en este grupo.', 'You will leave this group.'),
  ('voceSaiuDoGrupo', 'Você saiu do grupo', 'Salió del grupo', 'You left the group'),

  -- aba "Agenda"
  ('novoItemAgenda', 'Novo item', 'Nuevo elemento', 'New item'),
  ('editarItemAgenda', 'Editar item da agenda', 'Editar elemento de la agenda', 'Edit schedule item'),
  ('itemAgenda', 'Item da agenda', 'Elemento de la agenda', 'Schedule item'),
  ('itemAgendaObrigatorio', 'Selecione um item da agenda', 'Seleccione un elemento de la agenda', 'Select a schedule item'),
  ('nenhumItemAgenda', 'Nenhum item na agenda deste grupo', 'Ningún elemento en la agenda de este grupo', 'No items in this group''s schedule'),
  ('semData', 'Sem data', 'Sin fecha', 'No date'),
  ('data', 'Data', 'Fecha', 'Date'),
  ('hora', 'Hora', 'Hora', 'Time'),
  ('lembrete', 'Lembrete', 'Recordatorio', 'Reminder'),
  ('informeTituloAgenda', 'Informe o título do item', 'Ingrese el título del elemento', 'Enter the item title'),
  ('tituloAgendaMuitoLongo', 'O título pode ter até 128 caracteres', 'El título puede tener hasta 128 caracteres', 'The title can have up to 128 characters'),
  ('textoAgendaMuitoLongo', 'O texto pode ter até 4000 caracteres', 'El texto puede tener hasta 4000 caracteres', 'The text can have up to 4000 characters'),
  ('confirmarExclusaoItemAgenda', 'O item será excluído com as atividades dele.', 'El elemento se eliminará con sus actividades.', 'The item will be deleted along with its activities.'),

  -- aba "Atividades"
  ('novaAtividade', 'Nova atividade', 'Nueva actividad', 'New activity'),
  ('editarAtividade', 'Editar atividade', 'Editar actividad', 'Edit activity'),
  ('nenhumaAtividade', 'Nenhuma atividade neste item da agenda', 'Ninguna actividad en este elemento de la agenda', 'No activities in this schedule item'),
  ('livro', 'Livro', 'Libro', 'Book'),
  ('semLivro', 'Sem livro', 'Sin libro', 'No book'),
  ('concluida', 'Concluída', 'Completada', 'Completed'),
  ('marcarConcluida', 'Marcar como concluída', 'Marcar como completada', 'Mark as completed'),
  ('marcarPendente', 'Marcar como pendente', 'Marcar como pendiente', 'Mark as pending'),
  ('informeTextoOuLivro', 'Informe o texto ou escolha um livro', 'Ingrese el texto o elija un libro', 'Enter the text or choose a book'),
  ('confirmarExclusaoAtividade', 'A atividade será excluída.', 'La actividad se eliminará.', 'The activity will be deleted.'),

  -- agenda: repetição, fim da repetição e lembrete (configurações agendaRepeticao, agendaFimRepeticao e agendaLembrete)
  ('repeticao', 'Repetição', 'Repetición', 'Repeat'),
  ('fimRepeticao', 'Fim da repetição', 'Fin de la repetición', 'End of repeat'),
  ('naoInformado', 'Não informado', 'No informado', 'Not set'),
  ('repeticaoExigeData', 'Informe a data para definir a repetição', 'Ingrese la fecha para definir la repetición', 'Enter the date to set the repeat'),
  ('lembreteExigeData', 'Informe a data para definir o lembrete', 'Ingrese la fecha para definir el recordatorio', 'Enter the date to set the reminder'),
  ('opcaoAgendaInvalida', 'Opção não disponível. Atualize a agenda e escolha novamente', 'Opción no disponible. Actualice la agenda y elija de nuevo', 'Option not available. Refresh the schedule and choose again'),

  -- rótulos dos itens das configurações (configuracao_item.cite_valor)
  -- agendaRepeticao ('hora' já está na aba "Agenda" acima)
  ('diaInteiro', 'Dia inteiro', 'Todo el día', 'All day'),
  ('todosDiasSemana', 'Todos os dias da semana', 'Todos los días de la semana', 'Every weekday'),
  ('sabadoDomingo', 'Sábado e domingo', 'Sábado y domingo', 'Saturday and Sunday'),
  ('segunda', 'Segunda-feira', 'Lunes', 'Monday'),
  ('terca', 'Terça-feira', 'Martes', 'Tuesday'),
  ('quarta', 'Quarta-feira', 'Miércoles', 'Wednesday'),
  ('quinta', 'Quinta-feira', 'Jueves', 'Thursday'),
  ('sexta', 'Sexta-feira', 'Viernes', 'Friday'),
  ('sabado', 'Sábado', 'Sábado', 'Saturday'),
  ('domingo', 'Domingo', 'Domingo', 'Sunday'),
  ('mes', 'Mês', 'Mes', 'Month'),
  ('ano', 'Ano', 'Año', 'Year'),
  -- agendaFimRepeticao
  ('nunca', 'Nunca', 'Nunca', 'Never'),
  ('naData', 'Na data', 'En la fecha', 'On date'),
  -- agendaLembrete
  ('5minutos', '5 minutos antes', '5 minutos antes', '5 minutes before'),
  ('15minutos', '15 minutos antes', '15 minutos antes', '15 minutes before'),
  ('30minutos', '30 minutos antes', '30 minutos antes', '30 minutes before'),
  ('1hora', '1 hora antes', '1 hora antes', '1 hour before'),
  ('2hora', '2 horas antes', '2 horas antes', '2 hours before'),
  ('1dia', '1 dia antes', '1 día antes', '1 day before'),
  ('2dia', '2 dias antes', '2 días antes', '2 days before'),
  ('1semanas', '1 semana antes', '1 semana antes', '1 week before'),
  ('2semanas', '2 semanas antes', '2 semanas antes', '2 weeks before')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
