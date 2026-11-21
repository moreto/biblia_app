// Copyright 2024 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

abstract final class Routes {
  // access
  static const splash = '/';

  /// Tela de entrada: menu hambúrguer e botão "Bíblia".
  static const home = '/home';

  /// Home anterior (atalhos de tema, idioma e login e o card de funcionalidades).
  static const homeOld = '/home-old';
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

  /// Configurações de leitura, abertas pela AppBar da leitura (o viewmodel da leitura vai no `extra`).
  static const configuracoesLeitura = '/configuracoes-leitura';

  /// Escolha da versão da Bíblia, aberta pelas Configurações de leitura (viewmodel da leitura no `extra`).
  static const versaoBiblia = '/versao-biblia';

  /// Escolha da voz da narração (idioma → país → voz), aberta pelas Configurações de leitura.
  static const vozNarracao = '/voz-narracao';

  /// Versículos de um renomado: `/versiculo-renomado/:renoId` (o `RenomadoModel` pode ir no `extra`).
  static const versiculoRenomado = '/versiculo-renomado';

  /// Indicações de versículo que o usuário recebeu (tela própria, não é aba).
  static const versiculoIndicado = '/versiculo-indicado';

  // mensagem
  /// Mensagens recebidas pelo usuário (tela própria, não é aba).
  static const mensagemLista = '/mensagem-lista';

  // dicionario
  /// Busca no dicionário com o resultado na mesma página (tela própria, não é aba).
  static const dicionario = '/dicionario';

  // comunidade
  static const comunidade = '/comunidade';

  /// Todas as comunidades, filtradas por estado e cidade (tela "Encontrar comunidades").
  static const comunidadeLista = '/comunidade-lista';
}
