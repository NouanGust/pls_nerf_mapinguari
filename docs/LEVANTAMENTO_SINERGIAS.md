# Levantamento de sinergias — Folchess

Relatório atualizado para o elenco de **37 unidades**, incluindo as unidades de fauna e flora brasileiras e o Guaraná. Uma unidade conta para cada etiqueta que possui, então os grupos se sobrepõem. As quantidades e os efeitos abaixo são uma proposta de design: **o jogo ainda não ativa bônus de sinergia**.

## Resumo do elenco

- **37 unidades** e **21 sinergias candidatas**: 9 origens, 10 classes e 2 afinidades.
- As unidades somam **153 atribuições de etiquetas**: 51 de origem, 84 de classe e 18 de afinidade.
- O menor grupo tem 2 unidades; portanto, todas as etiquetas atuais podem ter ao menos um patamar.
- A composição máxima observada é de 11 unidades em campo (nível 9, limite `player_level + 2`). Os patamares propostos respeitam esse limite.
- `Aquático` aparece como origem e como classe. Manter os campos separados é importante para que a unidade conte em cada grupo sem confundir os conceitos.
- As novas espécies e seus dados estão documentados em [UNIDADES_BIODIVERSIDADE.md](UNIDADES_BIODIVERSIDADE.md).

## Origens

Os efeitos de origem representam vantagens temáticas da região. Os números entre parênteses são as unidades que têm a etiqueta.

| Origem | Unidades | Patamares e efeito proposto |
| --- | ---: | --- |
| Amazônico | 13 | **2/4/6/8:** regeneração gradual da equipe; a cada patamar, aumenta a recuperação. |
| Aquático | 2 | **2:** escudo inicial para a equipe, representando a proteção das águas. |
| Caatinga | 4 | **2/4:** resistência a dano; no segundo patamar, reduz também efeitos de controle recebidos. |
| Cerrado | 2 | **2:** chance da equipe de causar um acerto crítico após derrotar uma unidade. |
| Litorâneo | 7 | **2/4/6:** velocidade de ataque; os patamares mais altos acrescentam resistência a controle. |
| Mata Atlântica | 5 | **2/4:** regeneração de vida; no segundo patamar, concede cura adicional ao usar habilidades. |
| Pantaneiro | 8 | **2/4/6:** vida máxima e cura recebida para a equipe. |
| Sertanejo | 5 | **2/4/6:** resistência crescente quando a vida fica baixa. |
| Urbano | 5 | **2/4:** velocidade de ataque; no segundo patamar, o primeiro ataque contra um alvo causa dano extra. |

## Classes

As classes representam função de combate. Os efeitos devem reforçar a identidade do papel sem substituir as habilidades individuais.

| Classe | Unidades | Patamares e efeito proposto |
| --- | ---: | --- |
| Aquático | 5 | **2/4:** resistência mágica; no segundo patamar, habilidades de controle duram mais. |
| Assombração | 8 | **2/4/6:** chance de aplicar medo ou lentidão ao causar dano; os patamares aumentam a chance. |
| Caçador | 6 | **2/4/6:** marca o alvo com menos vida; unidades aliadas causam dano aumentado contra ele. |
| DPS | 10 | **2/4/6/8:** bônus de dano crescente. |
| Encantado | 5 | **2/4:** poder de habilidade; no segundo patamar, reduz o tempo de recarga. |
| Metamorfo | 2 | **2:** chance de esquivar do primeiro golpe recebido em cada combate. |
| Místico | 7 | **2/4/6:** poder de habilidade e geração de recurso para habilidades. |
| Protetor da Mata | 12 | **2/4/6/8:** armadura crescente para a equipe; no patamar máximo, pequena regeneração. |
| Suporte | 15 | **2/4/6/8:** aumenta cura e escudos concedidos; os patamares altos também fortalecem a equipe. |
| Tank | 14 | **2/4/6/8:** vida máxima e armadura crescentes. |

## Afinidades

Afinidades cruzam fauna e flora e podem coexistir com origem e classe na mesma unidade. Os bônus devem ser compartilhados pela equipe para que espécies de diferentes regiões possam formar uma composição conjunta.

| Afinidade | Unidades | Patamares e efeito proposto |
| --- | ---: | --- |
| Fauna | 9 | **2/4/6/8:** velocidade de ataque e movimento; em patamares altos, bônus ao atacar o mesmo alvo que um aliado. |
| Flora | 9 | **2/4/6/8:** cura e escudos recebidos; em patamares altos, chance de enraizar brevemente quem ataca a equipe. |

## Elenco por etiqueta

Esta relação permite conferir a contagem e visualizar quais unidades podem ativar cada grupo.

### Origens

| Origem | Elenco |
| --- | --- |
| Amazônico (13) | Alamoa, Anhangá, Boiúna, Caapora, Comadre Fulozinha, Guaraná, Labatut, Mapinguari, Matinta Perera, Onça-pintada, Quibungo, Sumaúma, Vitória-régia |
| Aquático (2) | Boiúna, Mãe-D'Água |
| Caatinga (4) | Arara-azul-de-lear, Ararinha-azul, Mandacaru, Tatu-bola-do-nordeste |
| Cerrado (2) | Lobo-guará, Tamanduá-bandeira |
| Litorâneo (7) | Alamoa, Cabeça-de-Cuia, Mãe-D'Água, Mboi-Guaçu, Mutum-de-alagoas, Palmito-juçara, Pau-brasil |
| Mata Atlântica (5) | Araucária, Brinco-de-princesa, Mutum-de-alagoas, Palmito-juçara, Pau-brasil |
| Pantaneiro (8) | Lobo-guará, Mãe-de-Ouro, Mboi-Guaçu, Minhocão, Onça-pintada, Romãozinho, Tamanduá-bandeira, Teiniaguá |
| Sertanejo (5) | Arara-azul-de-lear, Ararinha-azul, Mandacaru, Pé-de-Garrafa, Tatu-bola-do-nordeste |
| Urbano (5) | Corpo-Seco, Cumacanga, Papa-Figo, Pisadeira, Tutu-Marambá |

### Classes

| Classe | Elenco |
| --- | --- |
| Aquático (5) | Alamoa, Cabeça-de-Cuia, Labatut, Mboi-Guaçu, Vitória-régia |
| Assombração (8) | Cabeça-de-Cuia, Corpo-Seco, Cumacanga, Matinta Perera, Papa-Figo, Pé-de-Garrafa, Pisadeira, Tutu-Marambá |
| Caçador (6) | Arara-azul-de-lear, Ararinha-azul, Caapora, Lobo-guará, Onça-pintada, Pé-de-Garrafa |
| DPS (10) | Arara-azul-de-lear, Boiúna, Caapora, Cabeça-de-Cuia, Corpo-Seco, Cumacanga, Mãe-de-Ouro, Onça-pintada, Pé-de-Garrafa, Teiniaguá |
| Encantado (5) | Alamoa, Brinco-de-princesa, Comadre Fulozinha, Mãe-D'Água, Romãozinho |
| Metamorfo (2) | Matinta Perera, Romãozinho |
| Místico (7) | Boiúna, Guaraná, Labatut, Mãe-D'Água, Mãe-de-Ouro, Palmito-juçara, Teiniaguá |
| Protetor da Mata (12) | Anhangá, Araucária, Caapora, Comadre Fulozinha, Mandacaru, Mapinguari, Minhocão, Pau-brasil, Quibungo, Sumaúma, Tamanduá-bandeira, Tatu-bola-do-nordeste |
| Suporte (15) | Alamoa, Ararinha-azul, Brinco-de-princesa, Comadre Fulozinha, Guaraná, Labatut, Lobo-guará, Mãe-D'Água, Mãe-de-Ouro, Mutum-de-alagoas, Palmito-juçara, Papa-Figo, Pisadeira, Romãozinho, Vitória-régia |
| Tank (14) | Anhangá, Araucária, Boiúna, Mandacaru, Mapinguari, Mboi-Guaçu, Minhocão, Mutum-de-alagoas, Pau-brasil, Quibungo, Sumaúma, Tamanduá-bandeira, Tatu-bola-do-nordeste, Tutu-Marambá |

### Afinidades

| Afinidade | Elenco |
| --- | --- |
| Fauna (9) | Arara-azul-de-lear, Ararinha-azul, Boiúna, Lobo-guará, Mboi-Guaçu, Mutum-de-alagoas, Onça-pintada, Tamanduá-bandeira, Tatu-bola-do-nordeste |
| Flora (9) | Araucária, Brinco-de-princesa, Guaraná, Lobo-guará, Mandacaru, Palmito-juçara, Pau-brasil, Sumaúma, Vitória-régia |

## Como dividir a implementação

1. **Primeira rodada — patamares 2 e 4:** implementar e ajustar efeitos para todas as etiquetas com quatro ou mais unidades. Assim, quase todo o elenco participa desde o início e as sinergias menores não dependem de conteúdo futuro.
2. **Segunda rodada — patamares 6 e 8:** habilitar progressões para grupos com elenco suficiente e testar a viabilidade dentro do limite de 11 unidades em campo. O patamar 8 fica reservado aos grupos mais numerosos.
3. **Teste de composição:** avaliar em conjunto origem, classe e afinidade, pois unidades com várias etiquetas podem ativar bônus sobrepostos. Ajustar valores para que acumular três famílias de bônus não domine uma composição especializada.
4. **Texto e consistência:** definir duração, escopo, acumulação e apresentação visual de cada efeito antes de ativar as sinergias no jogo. Os efeitos listados aqui são direcionamentos temáticos, ainda sem números de balanceamento.

## Observações

- As sinergias Amazônico, DPS, Protetor da Mata, Suporte e Tank são as mais numerosas e merecem atenção especial no balanceamento.
- Aquático (origem), Cerrado e Metamorfo têm apenas duas unidades; por enquanto, um patamar em **2** evita criar níveis impossíveis de alcançar.
- Guaraná conta como origem Amazônico, classe Místico e Suporte. Lobo-guará conta como origem Cerrado e Pantaneiro, classe Caçador e Suporte, e afinidades Fauna e Flora, conforme as etiquetas atuais.
- As sinergias dependem das etiquetas presentes nos resources. Se novas unidades ou tags entrarem no elenco, atualizar contagens, patamares e efeitos deste relatório.
