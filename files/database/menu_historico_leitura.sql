-- Item de menu "Histórico de leitura" (rota /historico-leitura), filho do mesmo menu da leitura da Bíblia
-- (o pai do item com menu_rota = '/biblia-leitura'), logo depois dos irmãos já cadastrados.
-- menu_icone: chave de IconsMap.mdiIcons (app/lib/config/icons_map.dart).
-- O item recebe os mesmos perfis (menu_perfil) do item da leitura.
--
-- Idempotente, pela rota: não duplica o item nem os perfis. Se o menu da leitura não existir, nada é inserido
-- (cadastre o item pela tela /menu, como filho do menu Bíblia).
WITH leitura AS (
  SELECT m.menu_id, m.menu_parent_id
  FROM public.menu m
  WHERE m.menu_rota = '/biblia-leitura'
  ORDER BY m.menu_id
  LIMIT 1
)
INSERT INTO public.menu (menu_nome, menu_chave, menu_icone, menu_sequencia, menu_parent_id, menu_rota, menu_ativo)
SELECT 'Histórico de leitura', 'historicoLeitura', 'book-clock-outline',
       COALESCE((SELECT MAX(i.menu_sequencia) FROM public.menu i
                 WHERE i.menu_parent_id IS NOT DISTINCT FROM l.menu_parent_id), 0) + 1,
       l.menu_parent_id, '/historico-leitura', true
FROM leitura l
WHERE NOT EXISTS (SELECT 1 FROM public.menu m WHERE m.menu_rota = '/historico-leitura');

INSERT INTO public.menu_perfil (menu_id, perf_id)
SELECT h.menu_id, mp.perf_id
FROM public.menu h
JOIN public.menu l ON l.menu_rota = '/biblia-leitura'
JOIN public.menu_perfil mp ON mp.menu_id = l.menu_id
WHERE h.menu_rota = '/historico-leitura'
  AND NOT EXISTS (
    SELECT 1 FROM public.menu_perfil x WHERE x.menu_id = h.menu_id AND x.perf_id = mp.perf_id
  );
