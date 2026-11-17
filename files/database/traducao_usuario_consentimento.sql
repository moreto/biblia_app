-- Traduções da tela "Privacidade e consentimentos" (rota /usuario-consentimento; tela própria, não é aba): aceite e
-- revogação dos termos de cada finalidade (LGPD art. 8º e 11) em GET/POST/DELETE /v1/usuario-consentimento.
-- Idempotente: só insere chaves inexistentes (conferidas nos scripts files/database/traducao_*.sql e em
-- files/prompts/l10n.csv em 17/11/2026).
-- Chaves já existentes reutilizadas: voltar, ocultarAcoes, exibirAcoes, tentarNovamente, atualizar, cancelar,
-- dadosInvalidos, registroNaoEncontrado, respostaApiInvalida, erroGeralApi, tokenInvalido, headerInvalido.
-- consentimentoNecessario é a mensagem do 403 da API nas rotas que gravam dados religiosos sem o aceite.
INSERT INTO public.traducao (trad_chave, trad_pt_br, trad_es_es, trad_en_us, usua_id, trad_status, created_at)
SELECT v.trad_chave, v.trad_pt_br, v.trad_es_es, v.trad_en_us, 1, true, now()
FROM (VALUES
  ('privacidadeConsentimentos', 'Privacidade e consentimentos', 'Privacidad y consentimientos', 'Privacy and consents'),
  ('consentimentoIntro', 'Leia e aceite os termos abaixo para usar o app. Você pode revogar cada consentimento a qualquer momento, conforme a Lei Geral de Proteção de Dados (LGPD).', 'Lea y acepte los términos a continuación para usar la aplicación. Puede revocar cada consentimiento en cualquier momento, según la Ley General de Protección de Datos (LGPD).', 'Read and accept the terms below to use the app. You can revoke each consent at any time, under the Brazilian General Data Protection Law (LGPD).'),
  ('consentimentosEmDia', 'Todos os consentimentos estão aceitos', 'Todos los consentimientos están aceptados', 'All consents are accepted'),
  ('consentimentoTermosUso', 'Termos de uso', 'Términos de uso', 'Terms of use'),
  ('consentimentoTermosUsoDescricao', 'Regras de uso do app, responsabilidades do usuário e condições do serviço.', 'Reglas de uso de la aplicación, responsabilidades del usuario y condiciones del servicio.', 'Rules for using the app, user responsibilities and terms of service.'),
  ('consentimentoPoliticaPrivacidade', 'Política de privacidade', 'Política de privacidad', 'Privacy policy'),
  ('consentimentoPoliticaPrivacidadeDescricao', 'Como seus dados pessoais são coletados, usados, guardados e excluídos, e como exercer seus direitos de titular.', 'Cómo se recopilan, usan, guardan y eliminan sus datos personales, y cómo ejercer sus derechos como titular.', 'How your personal data is collected, used, stored and deleted, and how to exercise your rights as a data subject.'),
  ('consentimentoDadosReligiosos', 'Dados religiosos', 'Datos religiosos', 'Religious data'),
  ('consentimentoDadosReligiososDescricao', 'Autorizo o tratamento de dados que revelam minha convicção religiosa (leituras, reações, indicações de versículos e comunidades), dado sensível pela LGPD (art. 11, I). Sem este consentimento, essas informações não podem ser gravadas.', 'Autorizo el tratamiento de datos que revelan mi convicción religiosa (lecturas, reacciones, recomendaciones de versículos y comunidades), dato sensible según la LGPD (art. 11, I). Sin este consentimiento, esta información no puede guardarse.', 'I authorize the processing of data that reveals my religious beliefs (readings, reactions, verse recommendations and communities), sensitive data under the LGPD (art. 11, I). Without this consent, this information cannot be saved.'),
  ('consentimentoAceito', 'Aceito', 'Aceptado', 'Accepted'),
  ('consentimentoPendente', 'Pendente', 'Pendiente', 'Pending'),
  ('versaoTermo', 'Versão do termo', 'Versión del término', 'Terms version'),
  ('aceitoEm', 'Aceito em', 'Aceptado el', 'Accepted on'),
  ('revogadoEm', 'Revogado em', 'Revocado el', 'Revoked on'),
  ('aceitar', 'Aceitar', 'Aceptar', 'Accept'),
  ('aceitarTodos', 'Aceitar todos', 'Aceptar todos', 'Accept all'),
  ('revogar', 'Revogar', 'Revocar', 'Revoke'),
  ('revogarConsentimento', 'Revogar consentimento', 'Revocar consentimiento', 'Revoke consent'),
  ('revogarConsentimentoDescricao', 'O app deixará de usar seus dados para esta finalidade. Os dados já gravados não são apagados: para isso, exclua-os nas telas do app ou exclua sua conta.', 'La aplicación dejará de usar sus datos para esta finalidad. Los datos ya guardados no se eliminan: para ello, elimínelos en las pantallas de la aplicación o elimine su cuenta.', 'The app will stop using your data for this purpose. Data already saved is not deleted: to do so, delete it in the app screens or delete your account.'),
  ('revogarDadosReligiososAviso', 'Sem este consentimento, não será possível gravar leituras, reações, indicações de versículos e comunidades.', 'Sin este consentimiento, no será posible guardar lecturas, reacciones, recomendaciones de versículos y comunidades.', 'Without this consent, it will not be possible to save readings, reactions, verse recommendations and communities.'),
  ('historicoConsentimentos', 'Histórico de consentimentos', 'Historial de consentimientos', 'Consent history'),
  ('nenhumConsentimentoRegistrado', 'Nenhum consentimento registrado', 'Ningún consentimiento registrado', 'No consent recorded'),
  ('consentimentoRegistrado', 'Consentimento registrado', 'Consentimiento registrado', 'Consent recorded'),
  ('consentimentosRegistrados', 'Consentimentos registrados', 'Consentimientos registrados', 'Consents recorded'),
  ('consentimentoRevogado', 'Consentimento revogado', 'Consentimiento revocado', 'Consent revoked'),
  ('formatoConsentimentoInvalido', 'Formato dos consentimentos inválido', 'Formato de los consentimientos inválido', 'Invalid consent format'),
  ('consentimentoNecessario', 'Aceite o consentimento de dados religiosos em Privacidade e consentimentos para gravar esta informação', 'Acepte el consentimiento de datos religiosos en Privacidad y consentimientos para guardar esta información', 'Accept the religious data consent in Privacy and consents to save this information')
) AS v (trad_chave, trad_pt_br, trad_es_es, trad_en_us)
WHERE NOT EXISTS (SELECT 1 FROM public.traducao t WHERE t.trad_chave = v.trad_chave);
