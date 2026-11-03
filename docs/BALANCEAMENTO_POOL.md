# Pool e custos — rodada de balanceamento de 16/10/2026

Registro histórico da expansão da pool. Os atributos e sinergias foram revisados em [19/10/2026](BALANCEAMENTO_COMBATE_2026_10_19.md); consulte esse documento e [LEVANTAMENTO_SINERGIAS.md](LEVANTAMENTO_SINERGIAS.md) para as regras atuais.

## Distribuição

| Custo/tier | Antes | Agora | Elenco atual |
| --- | ---: | ---: | --- |
| 1 | 5 | 9 | Brinco-de-princesa, Cumacanga, Guaraná, Mandacaru, Tatu-bola-do-nordeste, Capivara, Sabiá-laranjeira, Bromélia, Pequi |
| 2 | 6 | 10 | Arara-azul-de-lear, Lobo-guará, Palmito-juçara, Papa-Figo, Tamanduá-bandeira, Vitória-régia, Jararaca, Caranguejo-uçá, Ipê-amarelo, Aguapé |
| 3 | 9 | 10 | Alamoa, Anhangá, Cabeça-de-Cuia, Labatut, Mãe-de-Ouro, Mapinguari, Matinta Perera, Minhocão, Quibungo, Teiniaguá |
| 4 | 10 | 9 | Araucária, Caapora, Comadre Fulozinha, Corpo-Seco, Mboi-Guaçu, Onça-pintada, Pau-brasil, Pisadeira, Sumaúma |
| 5 | 7 | 7 | Ararinha-azul, Boiúna, Mãe-D'Água, Mutum-de-alagoas, Pé-de-Garrafa, Romãozinho, Tutu-Marambá |

O elenco passa de **37 para 45**. Os custos 1 e 2 passam de **11 para 19 opções**, sendo **17 de fauna/flora**. Cumacanga (1g) e Papa-Figo (2g) permanecem como portas de entrada para Urbano/Assombração. Anhangá, Labatut, Teiniaguá, Mapinguari e Mãe-de-Ouro passam a custar 3.

## Oito novas unidades

| Unidade | Custo | Afinidade | Origem | Classe | Habilidade básica implementada |
| --- | ---: | --- | --- | --- | --- |
| Capivara | 1 | Fauna | Pantaneiro | Aquático, Tank | Renova um escudo próprio de 130 até ser consumido. |
| Sabiá-laranjeira | 1 | Fauna | Mata Atlântica | Caçador | Causa 95 de dano físico ao alvo atual. |
| Bromélia | 1 | Flora | Mata Atlântica, Litorâneo | Suporte | Recupera 90 de vida de até dois aliados feridos próximos. |
| Pequi | 1 | Flora | Cerrado | Místico | Causa 110 de dano mágico ao alvo atual. |
| Jararaca | 2 | Fauna | Mata Atlântica | Caçador, DPS | Causa 170 de dano físico ao alvo atual; prioriza inimigos com menos vida. |
| Caranguejo-uçá | 2 | Fauna | Litorâneo | Aquático, Tank | Causa 90 de dano físico ao alvo atual e renova um escudo próprio de 170. |
| Ipê-amarelo | 2 | Flora | Cerrado | Protetor da Mata, Tank | Renova um escudo próprio de 200 até ser consumido. |
| Aguapé | 2 | Flora | Pantaneiro | Aquático, Suporte | Recupera 140 de vida de até dois aliados feridos próximos. |

## Mudanças de custo

| Unidade | Antes | Agora |
| --- | ---: | ---: |
| Anhangá | 1 | 3 |
| Arara-azul-de-lear | 4 | 2 |
| Brinco-de-princesa | 2 | 1 |
| Guaraná | 2 | 1 |
| Labatut | 1 | 3 |
| Lobo-guará | 3 | 2 |
| Mãe-de-Ouro | 2 | 3 |
| Mandacaru | 2 | 1 |
| Mapinguari | 2 | 3 |
| Palmito-juçara | 3 | 2 |
| Papa-Figo | 1 | 2 |
| Tamanduá-bandeira | 3 | 2 |
| Tatu-bola-do-nordeste | 2 | 1 |
| Teiniaguá | 1 | 3 |
| Vitória-régia | 3 | 2 |

## Decisões de implementação

- Custo e tier mudam juntos: a loja sorteia por tier, portanto alterar só o preço não ampliaria a pool inicial. As chances por nível permanecem as mesmas.
- As unidades de fauna/flora rebaixadas receberam redução de vida, ataque, defesa e/ou cura conforme seu papel. Anhangá, Labatut, Teiniaguá e Papa-Figo receberam atributos adequados ao custo maior; Mapinguari e Mãe-de-Ouro já tinham números elevados.
- Habilidades genéricas de dano passam a funcionar também no custo 2. Cura usa o fluxo existente. Campos `ability_shield` e `ability_mana` permitem escudo próprio e concessão de mana.
- Escudos próprios são renovados pelo maior valor, sem acumular a cada conjuração, e recebem multiplicador de estrela e bônus de sinergia. A mana procura aliados visíveis em combate dentro do alcance, excluindo o conjurador e aliados já conjurando.
- Descrições das unidades baratas foram alinhadas aos efeitos básicos implementados. Habilidades antigas de custos altos ainda podem estar incompletas; esta rodada não implementa todos os efeitos avançados do elenco.
- As novas espécies usam cápsula e placeholder de ícone existentes; nomes e etiquetas identificam as cartas até a criação de arte própria. Os papéis de combate são interpretações de jogo.
- Evoluções continuam em três cópias da mesma estrela, até quatro estrelas; compras durante combate vão ao banco e as evoluções esperam a próxima preparação.
- Os geradores antigos em `Scripts/tools` preservam recursos existentes para evitar sobrescrever os novos custos e atributos. A fonte de verdade do balanceamento é `resources/units/*.tres`.

As composições e os patamares estão em [LEVANTAMENTO_SINERGIAS.md](LEVANTAMENTO_SINERGIAS.md). Os números são um ponto inicial de balanceamento, ainda sujeito a partidas de teste.

## Rodada de 26/10/2026 — Funções de Combate e Lendárias por Região

### 1. Funções de Combate (Roles)
Cada unidade foi atribuída formalmente a uma das 6 funções de combate:
- **Tank**: Dano baixo por ataque, mas alta defesa e escalonamento em vida e defesas. Habilidades amplificam seus poderes defensivos ou aplicam controle de grupo (CC). Ex: *Capivara, Mandacaru, Tatu-bola, Caranguejo-uçá, Ipê-amarelo, Anhangá, Minhocão, Sumaúma, Araucária, Tutu-Marambá*.
- **Conjurador**: Dano baixo por ataque, pouca defesa e vida, mas causam alto dano através de habilidades mágicas/arcanas. Ex: *Pequi, Cabeça-de-Cuia, Mãe-de-Ouro, Teiniaguá, Comadre Fulozinha, Alamoa, Boiúna*.
- **Atacante**: Dano crescente e alto ritmo de ataque, pouca vida e defesa. Ganham amplificação de dano ou velocidade de ataque a cada golpe consecutivo. Ex: *Sabiá-laranjeira, Arara-azul-de-lear, Caapora, Corpo-Seco, Lobo-guará*.
- **Assassino**: Dano explosivo com habilidade de execução em alvo único, pouca defesa e vida. Possuem preferência por unidades mais fracas (menor vida). Ex: *Cumacanga, Jararaca, Matinta Perera, Onça-pintada, Pisadeira, Romãozinho, Pé-de-Garrafa*.
- **Suporte**: Dano baixo por ataque, pouca defesa e vida. Habilidades buffam aliados (cura, escudo, mana) ou enfraquecem inimigos, e criam aura nos hexágonos ao redor concedendo bônus aos companheiros. Ex: *Brinco-de-princesa, Bromélia, Guaraná, Aguapé, Palmito-juçara, Vitória-régia, Papa-Figo, Labatut, Ararinha-azul, Mãe-D'Água, Mutum-de-alagoas*.
- **Porradeiro**: Dano alto por ataque, boa vida e defesa no combate corpo a corpo. Suas habilidades buscam se auto-buffar com dano, velocidade ou regeneração. Ex: *Tamanduá-bandeira, Quibungo, Pau-brasil, Mapinguari, Mboi-Guaçu*.

### 2. Distribuição de Lendárias (Custo 5) por Região
Cada região do jogo conta agora com pelo menos 1 unidade custo 5 (lendária), sendo que as regiões maiores possuem 2 lendárias:
- **Amazônico** (2): Boiúna (Conjurador) e Mapinguari (Porradeiro)
- **Caatinga** (1): Ararinha-azul (Suporte)
- **Cerrado** (1): Lobo-guará (Atacante/Suporte)
- **Litorâneo** (2): Mãe-D'Água (Suporte) e Alamoa (Conjurador)
- **Mata Atlântica** (2): Mutum-de-alagoas (Suporte/Tank) e Araucária (Tank)
- **Pantaneiro** (2): Romãozinho (Assassino) e Mboi-Guaçu (Porradeiro)
- **Urbano** (2): Tutu-Marambá (Tank) e Pisadeira (Assassino)
- **Sertanejo** (1): Pé-de-Garrafa (Assassino)

### 3. Esfera Visual de Escudo por Origem
Unidades afetadas por escudo recebem uma esfera translúcida sem colisão ao seu redor, cuja cor varia conforme a origem:
- **Classe / Sinergia**: Dourado / Âmbar translúcido
- **Próprio**: Ciano / Azul piscina translúcido
- **Jogador / Aliado**: Verde Esmeralda translúcido
- **Inimigo**: Vermelho Carmesim translúcido

### 4. Feedback de Colocação por Raridade
Ao posicionar unidades no tabuleiro, efeitos visuais (choque em anel, partículas escaladas e feixe vertical para T4/T5) e sonoros (modulação de pitch e chime comemorativo para lendárias) fornecem feedback condizente com a raridade do campeão.

