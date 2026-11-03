# Tela inicial, regiões e progressão

## Fluxo da partida

- Executar o projeto (F5) abre `Scenes/UI/Menu.tscn`, com **Jogar**, **Como jogar**, **Opções** e **Sair** (desktop).
- **Jogar** mostra seis regiões em um carrossel: Cerrado, Pantanal, Amazônia, Caatinga, Mata Atlântica e Litoral. Clique nas laterais/setas ou use as setas do teclado.
- A região central mostra seu representante, descrição e situação da campanha. O fundo acompanha a região. **Continuar** retoma a partida salva; **Iniciar campanha**, **Jogar novamente** e **Tentar novamente** iniciam uma partida quando a anterior não está ativa.
- A escolha define o adversário; a loja do jogador continua com o elenco completo.
- A tela da batalha informa a região, o nível inimigo e o round do próximo marco. O tooltip mostra estrelas por vaga e formação.
- Ao perder toda a vida, a campanha encerra em derrota. Ao vencer um inimigo que já estava no nível 9, a região é concluída. O relatório oferece **Voltar ao início** em ambos os casos.
- Uma nova campanha reinicia ouro, vida, XP, banco, loja e equipes; a conquista da região permanece registrada.
- Executar somente `Scenes/Main/main.tscn` (F6) usa a propriedade `region_id`, com Cerrado como padrão, e também retoma o salvamento ativo dessa região.
- **Esc / Pausa** congela a partida e oferece opções, tutorial e saída com salvamento. Veja `docs/MENUS_PAUSA_E_CAMPANHAS.md` para detalhes da retomada.

## XP e capacidade

O jogador começa no **nível 1, com 0 XP**. Cada fim de round concede **2 XP apenas ao jogador**, independentemente de vitória, derrota ou empate. O inimigo não usa XP: sua progressão vem dos marcos abaixo. O resultado só é resolvido uma vez. Todos os resultados avançam o número do round.

A curva existente foi mantida: para subir, são necessários `nível atual × 2` XP. O excesso passa ao próximo nível, inclusive se uma compra ultrapassar mais de um patamar. No nível 9, o XP para de acumular e a compra fica bloqueada, sem gastar ouro.

| Nível do jogador | XP até o próximo nível | Vagas no campo |
| --- | --- | --- |
| 1 | 2 | 1 |
| 2 | 4 | 2 |
| 3 | 6 | 3 |
| 4 | 8 | 4 |
| 5 | 10 | 5 |
| 6 | 12 | 6 |
| 7 | 14 | 7 |
| 8 | 16 | 8 |
| 9 | Máximo | 9 |

O jogador pode antecipar níveis comprando **4 XP por 4 ouro** pelo botão ou pela tecla **Q**, inclusive durante o combate. A compra de XP não permite colocar peças adicionais no meio da luta. O banco continua com 9 vagas independentes do nível.

## Marcos inimigos — atualização de 19/10/2026

| Rounds | Nível / peças | Estrelas, na ordem das vagas do elenco regional |
| --- | ---: | --- |
| 1–2 | 1 | 1 |
| 3–4 | 2 | 1, 1 |
| 5–6 | 3 | 2, 1, 1 |
| 7–8 | 4 | 2, 2, 1, 1 |
| 9–11 | 5 | 2, 2, 2, 1, 1 |
| 12–14 | 6 | 2, 2, 2, 2, 2, 1 |
| 15–17 | 7 | 3, 2, 2, 2, 2, 2, 1 |
| 18–20 | 8 | 3, 3, 2, 2, 2, 2, 2, 1 |
| 21 em diante | 9 | 3, 3, 3, 2, 2, 2, 2, 2, 2 |

Cada marco vale desde a preparação daquele round e permanece até o próximo. As evoluções são definidas por vaga, inclusive quando duas vagas usam a mesma espécie; não consomem cópias da loja do jogador. As primeiras peças ficam mais fortes ao longo da campanha. Esta curva usa até três estrelas inimigas; o teto de quatro estrelas do jogador permanece.

O desafio final não aumenta indefinidamente: a partir do round 21 a quantidade e as estrelas permanecem estáveis. A formação continua variando. A vitória contra nível 9 conclui a região; chegar ao round 21 ou vencer o nível 8 não basta.

## Equipes regionais

As listas estão em `Scripts/Systems/region_rosters.gd`. Cada nível acrescenta a próxima peça da lista, preservando as anteriores. Tanques (inclusive plantas tanque) e unidades corpo a corpo ocupam as duas linhas dianteiras; as demais unidades à distância ficam nas duas linhas de trás. Os grupos têm casas separadas, dentro do campo inimigo de 4 × 7, sem sobreposição.

O posicionamento alterna entre **Centro, Flanco esquerdo, Flanco direito e Dispersa** a cada round. Cada região começa em um ponto diferente desse ciclo. O cálculo depende apenas da região e do número do round: sair e retomar não sorteia outra formação. A mudança acontece na preparação, sem reposicionar combatentes durante a luta.

| Região | Ordem das peças, do nível 1 ao 9 |
| --- | --- |
| Cerrado | Pequi, Ipê-amarelo, Tamanduá-bandeira, Lobo-guará, Ipê-amarelo, Pequi, Tamanduá-bandeira, Lobo-guará, Ipê-amarelo |
| Pantanal | Capivara, Aguapé, Tamanduá-bandeira, Lobo-guará, Minhocão, Teiniaguá, Mãe-de-Ouro, Mboi-Guaçu, Romãozinho |
| Amazônia | Guaraná, Vitória-régia, Anhangá, Labatut, Mapinguari, Caapora, Comadre Fulozinha, Sumaúma, Boiúna |
| Caatinga | Tatu-bola, Mandacaru, Arara-azul-de-lear, Tatu-bola, Mandacaru, Arara-azul-de-lear, Tatu-bola, Mandacaru, Ararinha-azul |
| Mata Atlântica | Sabiá-laranjeira, Bromélia, Jararaca, Brinco-de-princesa, Palmito-juçara, Araucária, Pau-brasil, Araucária, Mutum-de-alagoas |
| Litoral | Bromélia, Caranguejo-uçá, Palmito-juçara, Cabeça-de-Cuia, Alamoa, Mboi-Guaçu, Pau-brasil, Mutum-de-alagoas, Mãe-D'Água |

As repetições cobrem regiões que ainda possuem menos de nove espécies no elenco. Continuam valendo as sinergias por **identidades únicas**, sem contar cópias extras. As estrelas inimigas seguem a tabela dos marcos. O jogador mantém sua evolução por trios.

Ao chegar ao nível 9, a formação inimiga fica completa. Vencê-la conclui a região. Empates e derrotas permitem tentar novamente enquanto o jogador tiver vida. A conclusão considera o nível que começou a luta, antes de avançar o número do round.

## Campanhas existentes

O round salvo passa a determinar o marco, as estrelas e a formação ao carregar. Os campos antigos `enemy_level` e `enemy_xp` são mantidos no arquivo para compatibilidade, mas não controlam mais a progressão; `enemy_xp` é gravado como zero. Progresso, ouro, XP e unidades do jogador são preservados. Um resultado salvo já contém o round seguinte: suas recompensas não são reaplicadas.

## Pontos de edição

- `Scripts/Systems/level_progression.gd`: teto, XP por round, XP por compra e curva do jogador.
- `Scripts/Systems/region_rosters.gd`: `ENEMY_STAGES` define rounds, níveis e estrelas; `COLUMN_ORDERS` define as quatro formações; `REGIONS` define os elencos.
- `Scripts/UI/main_menu.gd` e `Scenes/UI/Menu.tscn`: tela inicial, seleção e prévia.
- `Scripts/main.gd`: aplicação dos resultados, compra de XP, criação dos inimigos e capacidade do campo.
- `Scenes/UI/GameUI.tscn`: indicador da região no HUD.

Implementação revisada por leitura do código; ainda não executada em Godot nesta alteração.
