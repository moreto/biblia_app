// Copyright 2024 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

abstract final class Routes {
  // access
  static const splash = '/';
  static const home = '/home';
  static const login = '/login';
  static const registro = '/registro';

  // common
  static const dashboard = '/dashboard';
  static const loggof = '/loggof';

  // admin
  static const notificacao = '/notificacao';
  static const log = '/log';
  static const configuracao = '/configuracao';
  static const menu = '/menu';

  // biblia
  static const bibliaLeitura = '/biblia-leitura';
  static const renomado = '/renomado';

  /// Versículos de um renomado: `/versiculo-renomado/:renoId` (o `RenomadoModel` pode ir no `extra`).
  static const versiculoRenomado = '/versiculo-renomado';

  /// Indicações de versículo que o usuário recebeu (tela própria, não é aba).
  static const versiculoIndicado = '/versiculo-indicado';

  // mensagem
  /// Mensagens recebidas pelo usuário (tela própria, não é aba).
  static const mensagemLista = '/mensagem-lista';

  // comunidade
  static const comunidade = '/comunidade';

  /// Todas as comunidades, filtradas por estado e cidade (tela "Encontrar comunidades").
  static const comunidadeLista = '/comunidade-lista';
}
