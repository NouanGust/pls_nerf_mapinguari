# Menus, pausa e campanhas regionais

## Navegação

- O menu inicial oferece **Jogar**, **Como jogar**, **Opções** e **Sair**. Sair não aparece no navegador.
- O tutorial tem sete páginas: compras, posicionamento/venda, estrelas, sinergias, combate/XP, câmera/pausa e campanhas.
- A seleção exibe três cartões; o central é maior. As setas, o teclado (←/→) e os cartões laterais mudam a seleção.
- O retrato circular representa a unidade de maior custo da formação regional. Vida máxima desempata custos iguais. As artes existentes também compõem o fundo, com uma transição suave.
- Os cartões mostram progresso (round, HP e nível), derrota ou a conquista **Região concluída**.

## Pausa e opções

**Esc** ou **Pausa** abre o menu durante a preparação, luta ou relatório. Se houver um arraste em andamento, Esc primeiro o cancela. O botão continua visível com o HUD oculto.

A pausa congela movimento, ataques, projéteis, cronômetro e contagem dos efeitos temporários. **Continuar** retoma essa mesma batalha. O relógio `BattleClock` usa tempo de simulação; queimadura, lentidão e enfraquecimento não expiram enquanto o jogo está pausado.

Opções disponíveis no menu inicial e na pausa:

- Volume geral.
- Tela cheia, no desktop.
- Órbita automática da câmera.
- Sensibilidade da câmera.

As preferências são gravadas em `user://settings.cfg`. Os atalhos O, Home e o arraste com o botão do meio continuam disponíveis durante a partida.

## Salvamento e retomada

Existe **uma campanha ativa por região**, independente das demais. A gravação acontece após alterações de economia, loja, banco e posicionamento, na entrada da partida e na resolução de cada round. Um arraste é concluído ou cancelado antes de gravar.

Cada campanha preserva:

- Ouro, vida, nível e XP do jogador.
- Nível e XP do inimigo, round e sequências de resultados.
- Unidades do campo/banco, estrelas, valor de venda e casas de preparação.
- Ofertas ainda disponíveis e estado da trava da loja.
- Estado da campanha e conquista da região.

### O ponto de retomada depende da etapa

| Momento da saída | Ao continuar |
| --- | --- |
| Preparação | Mesmas unidades, posições, loja e recursos. |
| Combate | Preparação do mesmo round, com todas as compras/vendas e XP preservados. Combatentes recuperam a vida e retornam às casas iniciais. Trios pendentes são resolvidos nessa preparação. |
| Relatório | Próxima preparação. Recompensas e XP já aplicados não são concedidos novamente; a loja segue sua regra normal de atualização/trava. |
| Vitória contra nível 9 | Campanha encerrada e região concluída. É possível jogar novamente. |
| Vida do jogador esgotada | Campanha encerrada em derrota. É possível tentar novamente. |

O salvamento é um checkpoint de round: **não restaura a luta no meio de um ataque**. Somente pausar e continuar sem sair mantém o instante exato da luta.

Vencer um inimigo de nível 8 no round 20 ainda não conclui a região. O adversário chega ao nível 9 no marco do round 21; a vitória precisa ocorrer contra a formação que começou a luta nesse nível. A conquista permanece visível mesmo ao começar uma nova campanha nessa região. O inimigo não recebe XP: nível, estrelas e posicionamento são reconstruídos a partir da região e do round salvo.

## Arquivos e recuperação

Os arquivos ficam em `user://campaigns/<regiao>.json`. No Windows, com o nome atual do projeto, normalmente isso corresponde a `%APPDATA%/Godot/app_userdata/Folchess/campaigns/`. No editor, **Projeto → Abrir pasta de dados do usuário** permite localizá-los.

A escrita usa um arquivo temporário e mantém uma cópia `.bak` da versão anterior válida. Ao carregar, o jogo tenta a cópia caso o principal esteja ilegível. Se os dois forem inválidos, os arquivos são preservados e a campanha não é sobrescrita. Uma falha de gravação é mostrada na batalha e bloqueia a saída pelo menu até que seja possível salvar. Fechamento forçado pelo sistema pode recuperar apenas o último checkpoint já gravado.

No navegador, as campanhas pertencem aos dados locais do site: limpar esses dados ou usar uma sessão privada pode removê-las. Não há sincronização entre dispositivos.

## Onde editar

- `Scripts/UI/main_menu.gd`: menu inicial, carrossel, cartões e transição de fundo.
- `Assets/Shaders/region_portrait.gdshader`: recorte circular e borda do retrato.
- `Scripts/UI/game_overlay.gd`: pausa, tutorial e controles de opções.
- `Scripts/Systems/game_settings.gd`: preferências persistentes.
- `Scripts/Systems/campaign_store.gd`: formato, validação e gravação das campanhas.
- `Scripts/Systems/battle_clock.gd`: relógio que respeita a pausa.
- `Scripts/main.gd`: captura/restauração da partida e encerramento da campanha.
- `Scripts/Systems/region_rosters.gd`: formações e escolha do representante regional.

As mudanças desta etapa foram revisadas por leitura; não foi executada uma sessão de jogo nem uma bateria de testes nesta alteração.
