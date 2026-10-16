# Sinergias e elenco — Folchess

Atualizado em **16/10/2026**. Este documento descreve as regras implementadas em `Scripts/Systems/synergy_system.gd` e os **45 recursos de unidade**. Substitui a proposta anterior de ativação universal com duas unidades.

## Regras de ativação

- Só contam unidades visíveis e vivas no campo; reservas ficam fora da contagem.
- Cada `unit_id` conta uma vez por equipe, mesmo com várias cópias ou estrelas diferentes.
- Uma unidade contribui para todas as suas origens, classes e afinidades. Origem Aquático e classe Aquático são grupos separados.
- Cada regra aplica apenas o bônus do maior patamar alcançado, sem somar os patamares anteriores. Os bônus continuam compartilhados pela equipe.
- Grupos com patamar **1** ativam com qualquer uma de suas unidades; levar outra portadora não duplica o efeito. Não são exclusivos de uma espécie.
- A interface mostra apenas grupos representados no campo, incluindo os inativos; o tooltip lista todos os patamares e integrantes.

## Patamares implementados

| Categoria | Sinergia | Patamares | Unidades no elenco | Custo 1–2 | Efeitos por patamar |
| --- | --- | --- | ---: | ---: | --- |
| Origem | Amazônico | 3/6 | 13 | 2 | **3:** Regenera 4 de vida por segundo; **6:** Regenera 8 de vida por segundo |
| Origem | Aquático | 1 | 2 | 0 | **1:** Começa o combate com escudo de 8% da vida |
| Origem | Caatinga | 2/4 | 4 | 3 | **2:** Recebe 8% menos dano; **4:** Recebe 15% menos dano e resiste a controle |
| Origem | Cerrado | 2/4 | 4 | 4 | **2:** Ganha 6% de crítico por inimigo derrotado; **4:** Ganha 12% de crítico por inimigo derrotado |
| Origem | Litorâneo | 2/4 | 9 | 3 | **2:** +10% de velocidade de ataque; **4:** +20% de velocidade de ataque e resistência a controle |
| Origem | Mata Atlântica | 3/5 | 8 | 5 | **3:** Regenera 4 de vida por segundo; **5:** Regenera 8/s e cura de habilidades +15% |
| Origem | Pantaneiro | 3/5 | 10 | 4 | **3:** +8% de vida máxima e cura recebida; **5:** +15% de vida máxima e cura recebida |
| Origem | Sertanejo | 3/5 | 5 | 3 | **3:** Com pouca vida, recebe 10% menos dano; **5:** Com pouca vida, recebe 20% menos dano |
| Origem | Urbano | 2/4 | 5 | 2 | **2:** +10% de velocidade de ataque; primeiro golpe +15%; **4:** +20% de velocidade de ataque; primeiro golpe +30% |
| Classe | Aquático | 2/4 | 8 | 4 | **2:** +12 de resistência mágica; **4:** +24 de resistência mágica |
| Classe | Assombração | 2/4 | 8 | 2 | **2:** Ataques têm 15% de chance de desacelerar; **4:** Ataques têm 30% de chance de desacelerar |
| Classe | Caçador | 2/4 | 8 | 4 | **2:** Marca o alvo mais ferido; equipe causa +10% de dano; **4:** Marca o alvo mais ferido; equipe causa +20% de dano |
| Classe | DPS | 2/4 | 11 | 3 | **2:** +8% de dano causado; **4:** +16% de dano causado |
| Classe | Encantado | 2/4 | 5 | 1 | **2:** +15% de poder de habilidade e cura; **4:** +30% de poder de habilidade e cura |
| Classe | Metamorfo | 1 | 2 | 0 | **1:** 20% de chance de esquivar do primeiro golpe |
| Classe | Místico | 2/4 | 8 | 3 | **2:** +12% de poder de habilidade e geração de mana; **4:** +24% de poder de habilidade e geração de mana |
| Classe | Protetor da Mata | 2/4 | 13 | 4 | **2:** +12 de armadura; **4:** +24 de armadura e regenera 3 de vida/s |
| Classe | Suporte | 2/4 | 17 | 8 | **2:** +15% de cura e escudos concedidos; **4:** +30% de cura e escudos concedidos |
| Classe | Tank | 3/6 | 17 | 6 | **3:** +10% de vida máxima e 10 de armadura; **6:** +20% de vida máxima e 20 de armadura |
| Afinidade | Fauna | 3/6 | 13 | 8 | **3:** +10% de velocidade de ataque e movimento; **6:** +20% de velocidade; aliados focados causam +10% |
| Afinidade | Flora | 3/6 | 13 | 10 | **3:** +15% de cura e escudos recebidos; **6:** +30% de cura e escudos; 15% de chance de enraizar |

Amazônico começa em três e exige ao menos uma unidade de custo 3 ou mais nesta distribuição; Guaraná e Vitória-régia iniciam o caminho. Metamorfo aparece a partir do custo 3, e a origem Aquático está nas lendas de custo 5. As sinergias individuais têm bônus reduzidos para compensar a ativação com uma só unidade.

## Integrantes por sinergia

- **Origem — Amazônico (3/6):** Alamoa (3g), Anhangá (3g), Boiúna (5g), Caapora (4g), Comadre Fulozinha (4g), Guaraná (1g), Labatut (3g), Mapinguari (3g), Matinta Perera (3g), Onça-pintada (4g), Quibungo (3g), Sumaúma (4g), Vitória-régia (2g).
- **Origem — Aquático (1):** Boiúna (5g), Mãe-D'Água (5g).
- **Origem — Caatinga (2/4):** Arara-azul-de-lear (2g), Ararinha-azul (5g), Mandacaru (1g), Tatu-bola-do-nordeste (1g).
- **Origem — Cerrado (2/4):** Lobo-guará (2g), Tamanduá-bandeira (2g), Pequi (1g), Ipê-amarelo (2g).
- **Origem — Litorâneo (2/4):** Alamoa (3g), Cabeça-de-Cuia (3g), Mãe-D'Água (5g), Mboi-Guaçu (4g), Mutum-de-alagoas (5g), Palmito-juçara (2g), Pau-brasil (4g), Bromélia (1g), Caranguejo-uçá (2g).
- **Origem — Mata Atlântica (3/5):** Araucária (4g), Brinco-de-princesa (1g), Mutum-de-alagoas (5g), Palmito-juçara (2g), Pau-brasil (4g), Sabiá-laranjeira (1g), Bromélia (1g), Jararaca (2g).
- **Origem — Pantaneiro (3/5):** Lobo-guará (2g), Mãe-de-Ouro (3g), Mboi-Guaçu (4g), Minhocão (3g), Onça-pintada (4g), Romãozinho (5g), Tamanduá-bandeira (2g), Teiniaguá (3g), Capivara (1g), Aguapé (2g).
- **Origem — Sertanejo (3/5):** Arara-azul-de-lear (2g), Ararinha-azul (5g), Mandacaru (1g), Pé-de-Garrafa (5g), Tatu-bola-do-nordeste (1g).
- **Origem — Urbano (2/4):** Corpo-Seco (4g), Cumacanga (1g), Papa-Figo (2g), Pisadeira (4g), Tutu-Marambá (5g).
- **Classe — Aquático (2/4):** Alamoa (3g), Cabeça-de-Cuia (3g), Labatut (3g), Mboi-Guaçu (4g), Vitória-régia (2g), Capivara (1g), Caranguejo-uçá (2g), Aguapé (2g).
- **Classe — Assombração (2/4):** Cabeça-de-Cuia (3g), Corpo-Seco (4g), Cumacanga (1g), Matinta Perera (3g), Papa-Figo (2g), Pé-de-Garrafa (5g), Pisadeira (4g), Tutu-Marambá (5g).
- **Classe — Caçador (2/4):** Arara-azul-de-lear (2g), Ararinha-azul (5g), Caapora (4g), Lobo-guará (2g), Onça-pintada (4g), Pé-de-Garrafa (5g), Sabiá-laranjeira (1g), Jararaca (2g).
- **Classe — DPS (2/4):** Arara-azul-de-lear (2g), Boiúna (5g), Caapora (4g), Cabeça-de-Cuia (3g), Corpo-Seco (4g), Cumacanga (1g), Mãe-de-Ouro (3g), Onça-pintada (4g), Pé-de-Garrafa (5g), Teiniaguá (3g), Jararaca (2g).
- **Classe — Encantado (2/4):** Alamoa (3g), Brinco-de-princesa (1g), Comadre Fulozinha (4g), Mãe-D'Água (5g), Romãozinho (5g).
- **Classe — Metamorfo (1):** Matinta Perera (3g), Romãozinho (5g).
- **Classe — Místico (2/4):** Boiúna (5g), Guaraná (1g), Labatut (3g), Mãe-D'Água (5g), Mãe-de-Ouro (3g), Palmito-juçara (2g), Teiniaguá (3g), Pequi (1g).
- **Classe — Protetor da Mata (2/4):** Anhangá (3g), Araucária (4g), Caapora (4g), Comadre Fulozinha (4g), Mandacaru (1g), Mapinguari (3g), Minhocão (3g), Pau-brasil (4g), Quibungo (3g), Sumaúma (4g), Tamanduá-bandeira (2g), Tatu-bola-do-nordeste (1g), Ipê-amarelo (2g).
- **Classe — Suporte (2/4):** Alamoa (3g), Ararinha-azul (5g), Brinco-de-princesa (1g), Comadre Fulozinha (4g), Guaraná (1g), Labatut (3g), Lobo-guará (2g), Mãe-D'Água (5g), Mãe-de-Ouro (3g), Mutum-de-alagoas (5g), Palmito-juçara (2g), Papa-Figo (2g), Pisadeira (4g), Romãozinho (5g), Vitória-régia (2g), Bromélia (1g), Aguapé (2g).
- **Classe — Tank (3/6):** Anhangá (3g), Araucária (4g), Boiúna (5g), Mandacaru (1g), Mapinguari (3g), Mboi-Guaçu (4g), Minhocão (3g), Mutum-de-alagoas (5g), Pau-brasil (4g), Quibungo (3g), Sumaúma (4g), Tamanduá-bandeira (2g), Tatu-bola-do-nordeste (1g), Tutu-Marambá (5g), Capivara (1g), Caranguejo-uçá (2g), Ipê-amarelo (2g).
- **Afinidade — Fauna (3/6):** Arara-azul-de-lear (2g), Ararinha-azul (5g), Boiúna (5g), Lobo-guará (2g), Mboi-Guaçu (4g), Mutum-de-alagoas (5g), Onça-pintada (4g), Tamanduá-bandeira (2g), Tatu-bola-do-nordeste (1g), Capivara (1g), Sabiá-laranjeira (1g), Jararaca (2g), Caranguejo-uçá (2g).
- **Afinidade — Flora (3/6):** Araucária (4g), Brinco-de-princesa (1g), Guaraná (1g), Lobo-guará (2g), Mandacaru (1g), Palmito-juçara (2g), Pau-brasil (4g), Sumaúma (4g), Vitória-régia (2g), Bromélia (1g), Pequi (1g), Ipê-amarelo (2g), Aguapé (2g).

## Composições iniciais de exemplo

Todos os exemplos usam três unidades distintas, ficam disponíveis a partir do nível 3 e custam 4 moedas no total. A partida começa no nível 1, com uma vaga no campo.

| Composição | Sinergias ativas |
| --- | --- |
| Capivara + Sabiá-laranjeira + Jararaca | Fauna (3), Caçador (2) |
| Guaraná + Pequi + Ipê-amarelo | Flora (3), Cerrado (2), Místico (2) |
| Tatu-bola + Mandacaru + Arara-azul-de-lear | Caatinga (2), Sertanejo (3), Protetor da Mata (2) |
| Bromélia + Brinco-de-princesa + Palmito-juçara | Flora (3), Mata Atlântica (3), Litorâneo (2), Suporte (2); composição frágil, sem tanque |

Os números indicam o patamar ativo, não a quantidade total de etiquetas na composição. Todos os patamares cabem no elenco e no limite máximo atual de 9 unidades (uma por nível). O balanceamento de taxas de vitória e duração das lutas ainda requer partidas de teste.

Veja [BALANCEAMENTO_POOL.md](BALANCEAMENTO_POOL.md) para custos e movimentações do elenco.
