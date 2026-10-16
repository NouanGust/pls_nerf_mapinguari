# Tela inicial, regiões e progressão

## Fluxo da partida

- Executar o projeto (F5) abre `Scenes/UI/Menu.tscn`, com **Iniciar** e **Sair**.
- **Iniciar** mostra seis regiões: Cerrado, Pantanal, Amazônia, Caatinga, Mata Atlântica e Litoral.
- Selecionar uma região mostra a descrição e a ordem de entrada das nove peças adversárias. **Jogar** abre uma partida nova nessa região.
- A escolha define o adversário; a loja do jogador continua com o elenco completo.
- A tela da batalha informa a região, o nível inimigo e seu XP.
- Ao perder toda a vida, o relatório oferece **Voltar ao início**. Uma nova partida reinicia ouro, vida, XP, banco, loja e equipes.
- Executar somente `Scenes/Main/main.tscn` (F6) abre o combate diretamente; a propriedade `region_id` do nó Main define a região, com Cerrado como padrão.

## XP e capacidade

Ambos começam no **nível 1, com 0 XP**. Cada fim de round concede **2 XP aos dois lados**, independentemente de vitória, derrota ou empate. O resultado só é resolvido uma vez. Todos os resultados avançam o número do round.

A curva existente foi mantida: para subir, são necessários `nível atual × 2` XP. O excesso passa ao próximo nível, inclusive se uma compra ultrapassar mais de um patamar. No nível 9, o XP para de acumular e a compra fica bloqueada, sem gastar ouro.

| Nível | XP até o próximo nível | Primeiro round do inimigo nesse nível | Vagas no campo |
| --- | --- | --- | --- |
| 1 | 2 | 1 | 1 |
| 2 | 4 | 2 | 2 |
| 3 | 6 | 4 | 3 |
| 4 | 8 | 7 | 4 |
| 5 | 10 | 11 | 5 |
| 6 | 12 | 16 | 6 |
| 7 | 14 | 22 | 7 |
| 8 | 16 | 29 | 8 |
| 9 | Máximo | 37 | 9 |

O jogador pode antecipar níveis comprando **4 XP por 4 ouro** pelo botão ou pela tecla **Q**, inclusive durante o combate. A compra de XP não permite colocar peças adicionais no meio da luta. O banco continua com 9 vagas independentes do nível.

## Equipes regionais

As listas estão em `Scripts/Systems/region_rosters.gd`. Cada nível acrescenta a próxima peça da lista, preservando as anteriores. Unidades corpo a corpo ocupam a frente; unidades à distância ficam na retaguarda. As casas são fixas e distintas, na metade inimiga do tabuleiro.

| Região | Ordem das peças, do nível 1 ao 9 |
| --- | --- |
| Cerrado | Pequi, Ipê-amarelo, Tamanduá-bandeira, Lobo-guará, Ipê-amarelo, Pequi, Tamanduá-bandeira, Lobo-guará, Ipê-amarelo |
| Pantanal | Capivara, Aguapé, Tamanduá-bandeira, Lobo-guará, Minhocão, Teiniaguá, Mãe-de-Ouro, Mboi-Guaçu, Romãozinho |
| Amazônia | Guaraná, Vitória-régia, Anhangá, Labatut, Mapinguari, Caapora, Comadre Fulozinha, Sumaúma, Boiúna |
| Caatinga | Tatu-bola, Mandacaru, Arara-azul-de-lear, Tatu-bola, Mandacaru, Arara-azul-de-lear, Tatu-bola, Mandacaru, Ararinha-azul |
| Mata Atlântica | Sabiá-laranjeira, Bromélia, Jararaca, Brinco-de-princesa, Palmito-juçara, Araucária, Pau-brasil, Araucária, Mutum-de-alagoas |
| Litoral | Bromélia, Caranguejo-uçá, Palmito-juçara, Cabeça-de-Cuia, Alamoa, Mboi-Guaçu, Pau-brasil, Mutum-de-alagoas, Mãe-D'Água |

As repetições cobrem regiões que ainda possuem menos de nove espécies no elenco. Continuam valendo as sinergias por **identidades únicas**, sem contar cópias extras. As peças inimigas usam uma estrela; a progressão desta etapa aumenta a quantidade e diversifica a formação. O jogador mantém a evolução de estrelas já existente.

Ao chegar ao nível 9, a formação inimiga fica completa e permanece nesse teto nos rounds seguintes. Esta etapa não adiciona uma condição de vitória de campanha.

## Pontos de edição

- `Scripts/Systems/level_progression.gd`: teto, XP por round, XP por compra e curva compartilhada.
- `Scripts/Systems/region_rosters.gd`: nomes, cores, descrições, ordem das unidades e formação.
- `Scripts/UI/main_menu.gd` e `Scenes/UI/Menu.tscn`: tela inicial, seleção e prévia.
- `Scripts/main.gd`: aplicação dos resultados, compra de XP, criação dos inimigos e capacidade do campo.
- `Scenes/UI/GameUI.tscn`: indicador da região no HUD.

Implementação revisada por leitura do código; ainda não executada em Godot nesta alteração.
