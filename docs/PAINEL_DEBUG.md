# Painel de debug

Durante a partida, pressione **F8** ou clique em **Debug · F8**. O painel pausa a simulação e foca o campo de comandos. **Enter** executa, **↑/↓** navegam pelo histórico, **Esc/F8** fecham. Se já havia um menu de pausa aberto, ele continua pausado ao fechar o console.

| Comando | Efeito |
| --- | --- |
| `ajuda` | Lista comandos e exemplos. |
| `avancar` ou `pular` | Conclui o round como vitória, com ouro, XP e streak normais, sem aguardar relatório. Funciona na preparação e no combate; a vitória final encerra a campanha normalmente. |
| `round 12` | Vai diretamente ao round 12 durante a preparação, recriando os inimigos e sem conceder recompensas. Resultados a partir do destino são removidos. |
| `acelerar 2` | Simulação a 2× após fechar o painel. Aceita 0.25 a 4; `acelerar 1` restaura. |
| `gold 100` | Adiciona 100 de ouro. |
| `streak 5` ou `setrak 5` | Define sequência de cinco vitórias. |
| `streak 3 loss` | Define sequência de três derrotas. A sequência oposta é zerada. |
| `unidades` ou `unidades mapinguari` | Lista IDs e nomes, opcionalmente filtrados. |
| `unidade mapinguari 1 3` | Entrega uma unidade com três estrelas no banco, sem custo. Quantidade e estrelas são opcionais, com padrão 1. |
| `xp 20` | Concede experiência respeitando o nível máximo. |
| `vida 100` | Define a vida do jogador entre 1 e 100. |
| `status` | Exibe round, recursos, streak e velocidade. |
| `limpar` / `fechar` | Limpa o histórico visual / fecha o painel. |

As unidades usam as fusões normais do jogo. Toda a quantidade solicitada precisa caber no banco antes da entrega. Estrelas aceitam valores de 1 a 4; streaks, de 0 a 5. Comandos inválidos mostram uma mensagem sem modificar o estado. Durante entradas, cutscenes e relatórios, feche o console e conclua a transição antes de alterar a partida.

Ouro, unidades e progresso alterados pelo debug **são salvos na campanha**. A velocidade vale apenas para a cena atual e é restaurada ao sair. O painel pode ser desativado na propriedade `debug_console_enabled` do nó principal.

Teste automatizado: `tests/test_debug_console.gd`, usando Godot 4.6 com `--headless --path . --script res://tests/test_debug_console.gd`. Defina `APPDATA` para uma pasta temporária cujo nome contenha `debug-console-test` antes de executar, para isolar os saves do teste.
