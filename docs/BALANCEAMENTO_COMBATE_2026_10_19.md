# Ajustes de combate e interface — 19/10/2026

## Diagnóstico

Escudos recebiam mana dos ataques absorvidos, dos próprios ataques e da regeneração. Isso permitia preparar o próximo escudo enquanto o anterior ainda protegia a unidade. Nos tanques baratos, a combinação de muita vida, armadura e renovação de escudo favorecia empates por tempo. Suportes baratos também combinavam cura de dois alvos, mana por segundo e vários bônus defensivos de sinergias.

A loja e o relatório compartilhavam a mesma camada. Elementos das cartas com prioridade de desenho podiam aparecer sobre o relatório. A rolagem externa do relatório também permitia que seu rodapé ficasse fora da área visível.

## Escudos e mana

- Todo escudo ativo bloqueia mana por ataque, dano recebido, regeneração e habilidades de aliados.
- O golpe que quebra o escudo não concede mana ao defensor, mesmo se parte do dano atingir a vida.
- Habilidades que concedem mana ignoram aliados com escudo para escolher outros alvos elegíveis.
- Conjuração também bloqueia ganho de mana e conjurações recursivas durante sua execução.
- Escudos continuam usando o maior valor, sem acumular a cada aplicação. Valores de habilidade mantêm o multiplicador de estrelas e os bônus existentes.
- A faixa ciano abaixo da vida mostra o escudo restante. O texto `ESC` mostra seu valor e a barra de mana fica acinzentada enquanto o ganho está bloqueado.
- Escudos são limpos na morte, no renascimento e na preparação seguinte.

## Tanques iniciais — valores base de uma estrela

| Unidade | Vida | Armadura | Escudo | Mana por golpe recebido | Outros ajustes |
| --- | --- | --- | --- | --- | --- |
| Capivara | 680 → 580 | 25 → 20 | 130 → 90 | 10 → 8 | — |
| Tatu-bola-do-nordeste | 700 → 600 | 35 → 25 | 160 → 110 | 10 → 8 | — |
| Mandacaru | 650 → 570 | 30 → 25 | 80 → 60 | 14 → 8 | Ataque 42 → 38; habilidade 75 → 65; mana/s 5 → 3 |
| Caranguejo-uçá | 880 → 780 | 45 → 35 | 170 → 130 | 10 → 8 | Dano de habilidade mantido em 90 |
| Ipê-amarelo | 820 → 760 | 35 → 30 | 200 → 150 | 10 → 8 | Mana/s 5 → 3 |
| Tamanduá-bandeira | 850 → 780 | 35 → 30 | 140 → 110 | 14 → 8 | Dano de habilidade mantido em 100 |

## Cura, apoio e dano inicial

| Unidade | Ajuste |
| --- | --- |
| Brinco-de-princesa | Cura por alvo 90 → 60; custo de mana 80 → 90 |
| Bromélia | Cura por alvo 90 → 65; custo de mana 80 → 90 |
| Aguapé | Cura por alvo 140 → 110; custo de mana 85 → 100 |
| Vitória-régia | Cura por alvo 130 → 100; custo de mana 90 → 100 |
| Palmito-juçara | Cura por alvo 90 → 75; mana concedida 15 → 10; custo de mana 85 → 100 |
| Guaraná | Mana concedida por alvo 20 → 15; custo de mana 70 → 85 |
| Lobo-guará | Cura por alvo 90 → 70; ataque 60 → 55 |
| Papa-Figo | Cura 110 → 80; dano de habilidade 130 → 115 |
| Pequi | Dano de habilidade 110 → 95; mana/s 5 → 3 |
| Cumacanga | Ataque 50 → 44; mana por ataque 15 → 12 |

Brinco-de-princesa, Bromélia, Aguapé, Vitória-régia, Palmito-juçara e Guaraná também passam de 5 para 3 mana/s e de 10 para 5 mana por golpe recebido. A quantidade de alvos das habilidades foi preservada. Sabiá-laranjeira, Jararaca e Arara-azul-de-lear foram revisados sem alteração de atributos nesta rodada. Queimadura mantém a redução de 60% na cura recebida.

## Sinergias

Os 45 recursos passam a ter exatamente uma origem e uma ou duas classes. O carregador rejeita novos cadastros fora desse formato, incluindo classes repetidas. Fauna/Flora ficam como tipos descritivos e deixam de ativar bônus, evitando uma quarta sinergia oculta.

- Bromélia e Alamoa ficam com origem Litorâneo; as demais unidades de múltiplas origens mantêm sua primeira origem cadastrada.
- Classes em excesso foram selecionadas conforme a identidade da unidade, sem alterar sua IA ou habilidade.
- Aquático fica somente como classe. Sertanejo fica exclusivo de Pé-de-Garrafa, com patamar 1 e redução de 10% do dano recebido abaixo de metade da vida.
- Contagem de cópias únicas, bônus compartilhados pela equipe e painel de grupos ativos/inativos foram preservados.
- Tutorial, tooltips e inspeção distinguem tipos informativos de sinergias.

A distribuição completa está em [LEVANTAMENTO_SINERGIAS.md](LEVANTAMENTO_SINERGIAS.md).

## Relatório de combate

- Camada própria 50, acima do HUD/loja e abaixo da pausa, que usa camada 100.
- Somente a lista de unidades tem rolagem. Cabeçalho, filtros e botão Continuar ficam no layout fixo do painel.
- Atalhos da partida ficam bloqueados durante o resultado; Esc continua abrindo a pausa.
- Clique duplo no botão de continuar não avança duas vezes.

## Alcance da revisão

Foi feita análise do código e conferência dos dados: 45 unidades dentro do limite e 18 sinergias com patamares alcançáveis. Não foram executadas partidas nem testes na engine nesta alteração. Os números são uma primeira rodada de ajuste; equilíbrio final e apresentação visual ainda precisam ser observados em jogo.

Campanhas existentes continuam usando os mesmos IDs, estrelas e progresso, com os novos atributos ao carregar uma nova sessão. A pool em memória exige reiniciar a execução do jogo para refletir os recursos alterados.
