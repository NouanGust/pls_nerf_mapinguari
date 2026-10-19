# Sinergias e elenco — Folchess

Atualizado em **19/10/2026**. Fonte: `Scripts/Systems/synergy_system.gd` e os 45 recursos em `resources/units`.

## Regras de ativação

- Cada unidade possui **uma origem e uma ou duas classes**, totalizando no máximo três sinergias.
- Fauna e Flora permanecem como tipos informativos, sem contagem, efeitos ou entradas no painel de sinergias.
- Só contam unidades visíveis e vivas no campo. Banco não conta; cada `unit_id` conta uma vez por equipe, independentemente das cópias e estrelas.
- Cada sinergia aplica somente o maior patamar alcançado. Os bônus continuam compartilhados pela equipe.
- O painel mostra apenas grupos representados no campo, ativos ou inativos; o tooltip lista os integrantes disponíveis.
- Aquático é apenas classe. A antiga origem Aquático foi removida para evitar duas classificações com o mesmo nome.
- Sertanejo passa a ser uma origem exclusiva de Pé-de-Garrafa, ativada com uma unidade; Metamorfo também mantém ativação individual.
- Todos os patamares abaixo são alcançáveis com espécies diferentes. Habitats/biomas não concedem origens extras.

## Patamares e distribuição

| Categoria | Sinergia | Patamares | Elenco | Custo 1–2 | Efeitos |
| --- | --- | --- | ---: | ---: | --- |
| Origem | Amazônico | 3/6 | 12 | 2 | Regenera 4 de vida por segundo; Regenera 8 de vida por segundo |
| Origem | Caatinga | 2/4 | 4 | 3 | Recebe 8% menos dano; Recebe 15% menos dano e resiste a controle |
| Origem | Cerrado | 2/4 | 4 | 4 | Ganha 6% de crítico por inimigo derrotado; Ganha 12% de crítico por inimigo derrotado |
| Origem | Litorâneo | 2/4 | 5 | 2 | +10% de velocidade de ataque; +20% de velocidade de ataque e resistência a controle |
| Origem | Mata Atlântica | 3/5 | 7 | 4 | Regenera 4 de vida por segundo; Regenera 8/s e cura de habilidades +15% |
| Origem | Pantaneiro | 3/5 | 7 | 2 | +8% de vida máxima e +15% de cura recebida; +15% de vida máxima e +30% de cura recebida |
| Origem | Sertanejo | 1 | 1 | 0 | Com pouca vida, recebe 10% menos dano |
| Origem | Urbano | 2/4 | 5 | 2 | +10% de velocidade de ataque; primeiro golpe +15%; +20% de velocidade de ataque; primeiro golpe +30% |
| Classe | Aquático | 2/4 | 8 | 4 | +12 de resistência mágica; +24 de resistência mágica |
| Classe | Assombração | 2/4 | 7 | 2 | Ataques têm 15% de chance de desacelerar; Ataques têm 30% de chance de desacelerar |
| Classe | Caçador | 2/4 | 8 | 4 | Marca o alvo mais ferido; equipe causa +10% de dano; Marca o alvo mais ferido; equipe causa +20% de dano |
| Classe | DPS | 2/4 | 8 | 3 | +8% de dano causado; +16% de dano causado |
| Classe | Encantado | 2/4 | 5 | 1 | +15% de cura realizada; +30% de cura realizada |
| Classe | Metamorfo | 1 | 2 | 0 | 20% de chance de esquivar do primeiro golpe |
| Classe | Místico | 2/4 | 6 | 3 | +12% de cura realizada e +10% de geração de mana; +24% de cura realizada e +20% de geração de mana |
| Classe | Protetor da Mata | 2/4 | 13 | 4 | +12 de armadura; +24 de armadura e regenera 3 de vida/s |
| Classe | Suporte | 2/4 | 13 | 8 | +15% de cura e escudos concedidos; +30% de cura e escudos concedidos |
| Classe | Tank | 3/6 | 17 | 6 | +10% de vida máxima e 10 de armadura; +20% de vida máxima e 20 de armadura |

## Integrantes por sinergia

- **Origem — Amazônico:** Guaraná (1g), Vitória-régia (2g), Anhangá (3g), Labatut (3g), Mapinguari (3g), Matinta Perera (3g), Quibungo (3g), Caapora (4g), Comadre Fulozinha (4g), Onça-pintada (4g), Sumaúma (4g), Boiúna (5g).
- **Origem — Caatinga:** Mandacaru (1g), Tatu-bola-do-nordeste (1g), Arara-azul-de-lear (2g), Ararinha-azul (5g).
- **Origem — Cerrado:** Pequi (1g), Ipê-amarelo (2g), Lobo-guará (2g), Tamanduá-bandeira (2g).
- **Origem — Litorâneo:** Bromélia (1g), Caranguejo-uçá (2g), Alamoa (3g), Cabeça-de-Cuia (3g), Mãe-D'Água (5g).
- **Origem — Mata Atlântica:** Brinco-de-princesa (1g), Sabiá-laranjeira (1g), Jararaca (2g), Palmito-juçara (2g), Araucária (4g), Pau-brasil (4g), Mutum-de-alagoas (5g).
- **Origem — Pantaneiro:** Capivara (1g), Aguapé (2g), Mãe-de-Ouro (3g), Minhocão (3g), Teiniaguá (3g), Mboi-Guaçu (4g), Romãozinho (5g).
- **Origem — Sertanejo:** Pé-de-Garrafa (5g).
- **Origem — Urbano:** Cumacanga (1g), Papa-Figo (2g), Corpo-Seco (4g), Pisadeira (4g), Tutu-Marambá (5g).
- **Classe — Aquático:** Capivara (1g), Aguapé (2g), Caranguejo-uçá (2g), Vitória-régia (2g), Alamoa (3g), Cabeça-de-Cuia (3g), Labatut (3g), Mboi-Guaçu (4g).
- **Classe — Assombração:** Cumacanga (1g), Papa-Figo (2g), Cabeça-de-Cuia (3g), Matinta Perera (3g), Corpo-Seco (4g), Pisadeira (4g), Tutu-Marambá (5g).
- **Classe — Caçador:** Sabiá-laranjeira (1g), Arara-azul-de-lear (2g), Jararaca (2g), Lobo-guará (2g), Caapora (4g), Onça-pintada (4g), Ararinha-azul (5g), Pé-de-Garrafa (5g).
- **Classe — DPS:** Cumacanga (1g), Arara-azul-de-lear (2g), Jararaca (2g), Mãe-de-Ouro (3g), Teiniaguá (3g), Corpo-Seco (4g), Onça-pintada (4g), Pé-de-Garrafa (5g).
- **Classe — Encantado:** Brinco-de-princesa (1g), Alamoa (3g), Comadre Fulozinha (4g), Mãe-D'Água (5g), Romãozinho (5g).
- **Classe — Metamorfo:** Matinta Perera (3g), Romãozinho (5g).
- **Classe — Místico:** Guaraná (1g), Pequi (1g), Palmito-juçara (2g), Mãe-de-Ouro (3g), Teiniaguá (3g), Boiúna (5g).
- **Classe — Protetor da Mata:** Mandacaru (1g), Tatu-bola-do-nordeste (1g), Ipê-amarelo (2g), Tamanduá-bandeira (2g), Anhangá (3g), Mapinguari (3g), Minhocão (3g), Quibungo (3g), Araucária (4g), Caapora (4g), Comadre Fulozinha (4g), Pau-brasil (4g), Sumaúma (4g).
- **Classe — Suporte:** Brinco-de-princesa (1g), Bromélia (1g), Guaraná (1g), Aguapé (2g), Lobo-guará (2g), Palmito-juçara (2g), Papa-Figo (2g), Vitória-régia (2g), Labatut (3g), Pisadeira (4g), Ararinha-azul (5g), Mãe-D'Água (5g), Mutum-de-alagoas (5g).
- **Classe — Tank:** Capivara (1g), Mandacaru (1g), Tatu-bola-do-nordeste (1g), Caranguejo-uçá (2g), Ipê-amarelo (2g), Tamanduá-bandeira (2g), Anhangá (3g), Mapinguari (3g), Minhocão (3g), Quibungo (3g), Araucária (4g), Mboi-Guaçu (4g), Pau-brasil (4g), Sumaúma (4g), Boiúna (5g), Mutum-de-alagoas (5g), Tutu-Marambá (5g).

## Cadastro completo

| Unidade | Custo | Origem | Classes |
| --- | ---: | --- | --- |
| Brinco-de-princesa | 1 | Mata Atlântica | Suporte, Encantado |
| Bromélia | 1 | Litorâneo | Suporte |
| Capivara | 1 | Pantaneiro | Aquático, Tank |
| Cumacanga | 1 | Urbano | Assombração, DPS |
| Guaraná | 1 | Amazônico | Místico, Suporte |
| Mandacaru | 1 | Caatinga | Tank, Protetor da Mata |
| Pequi | 1 | Cerrado | Místico |
| Sabiá-laranjeira | 1 | Mata Atlântica | Caçador |
| Tatu-bola-do-nordeste | 1 | Caatinga | Tank, Protetor da Mata |
| Aguapé | 2 | Pantaneiro | Aquático, Suporte |
| Arara-azul-de-lear | 2 | Caatinga | Caçador, DPS |
| Caranguejo-uçá | 2 | Litorâneo | Aquático, Tank |
| Ipê-amarelo | 2 | Cerrado | Protetor da Mata, Tank |
| Jararaca | 2 | Mata Atlântica | Caçador, DPS |
| Lobo-guará | 2 | Cerrado | Caçador, Suporte |
| Palmito-juçara | 2 | Mata Atlântica | Suporte, Místico |
| Papa-Figo | 2 | Urbano | Assombração, Suporte |
| Tamanduá-bandeira | 2 | Cerrado | Tank, Protetor da Mata |
| Vitória-régia | 2 | Amazônico | Aquático, Suporte |
| Alamoa | 3 | Litorâneo | Aquático, Encantado |
| Anhangá | 3 | Amazônico | Protetor da Mata, Tank |
| Cabeça-de-Cuia | 3 | Litorâneo | Aquático, Assombração |
| Labatut | 3 | Amazônico | Aquático, Suporte |
| Mãe-de-Ouro | 3 | Pantaneiro | Místico, DPS |
| Mapinguari | 3 | Amazônico | Protetor da Mata, Tank |
| Matinta Perera | 3 | Amazônico | Assombração, Metamorfo |
| Minhocão | 3 | Pantaneiro | Protetor da Mata, Tank |
| Quibungo | 3 | Amazônico | Protetor da Mata, Tank |
| Teiniaguá | 3 | Pantaneiro | Místico, DPS |
| Araucária | 4 | Mata Atlântica | Tank, Protetor da Mata |
| Caapora | 4 | Amazônico | Protetor da Mata, Caçador |
| Comadre Fulozinha | 4 | Amazônico | Protetor da Mata, Encantado |
| Corpo-Seco | 4 | Urbano | Assombração, DPS |
| Mboi-Guaçu | 4 | Pantaneiro | Aquático, Tank |
| Onça-pintada | 4 | Amazônico | Caçador, DPS |
| Pau-brasil | 4 | Mata Atlântica | Tank, Protetor da Mata |
| Pisadeira | 4 | Urbano | Assombração, Suporte |
| Sumaúma | 4 | Amazônico | Tank, Protetor da Mata |
| Ararinha-azul | 5 | Caatinga | Caçador, Suporte |
| Boiúna | 5 | Amazônico | Místico, Tank |
| Mãe-D'Água | 5 | Litorâneo | Encantado, Suporte |
| Mutum-de-alagoas | 5 | Mata Atlântica | Tank, Suporte |
| Pé-de-Garrafa | 5 | Sertanejo | Caçador, DPS |
| Romãozinho | 5 | Pantaneiro | Encantado, Metamorfo |
| Tutu-Marambá | 5 | Urbano | Assombração, Tank |

## Exemplos de composições iniciais

- Capivara + Aguapé: Aquático (2).
- Guaraná + Pequi + Ipê-amarelo: Místico (2), Cerrado (2).
- Tatu-bola + Mandacaru + Arara-azul-de-lear: Caatinga (2), Protetor da Mata (2).
- Bromélia + Caranguejo-uçá: Litorâneo (2).
- Brinco-de-princesa + Sabiá-laranjeira + Palmito-juçara: Mata Atlântica (3), Suporte (2).

O detalhamento dos ajustes de combate está em [BALANCEAMENTO_COMBATE_2026_10_19.md](BALANCEAMENTO_COMBATE_2026_10_19.md).
