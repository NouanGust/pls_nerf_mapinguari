# Proposta de novas origens, sinergias e equipes regionais

**Versão:** 1 — proposta para protótipo, 27/10/2026.  
**Escopo:** as 66 unidades reunidas na pesquisa; seis equipes de nove unidades distintas, cada uma com duas lendárias.  
**Entrega:** documento de design. Nenhum recurso de unidade, habilidade ou regra do jogo foi alterado nesta etapa.

## 1. Decisão central

Proponho **nove origens temáticas**, baseadas nas relações entre histórias, elementos, seres vivos e modos de aparecer. Cada unidade recebe **duas origens e uma única função de combate**. As duas origens têm o mesmo peso: a ordem na tabela não indica principal e secundária.

**Região**, **origem** e **função** passam a responder a perguntas diferentes:

- **Região:** em qual equipe de campanha essa unidade aparece? Uma unidade pode aparecer em mais de uma.
- **Origem:** com quais outras unidades ela compartilha uma afinidade capaz de ativar uma sinergia?
- **Função:** como ela causa impacto em combate, onde deve ficar e quais são suas fragilidades?

As seis regiões solicitadas permanecem como cenários e equipes. Elas não concedem bônus só por reunir personagens associados ao mesmo lugar. As antigas origens e classes não participam dos cálculos desta proposta.

Os seis papéis definidos pelo usuário **não ativam uma segunda camada de bônus automáticos nesta versão**. Eles orientam atributos, habilidades e composição. Isso evita que nove unidades com duas origens ainda acumulem mais seis famílias de bônus de função.

A base cultural está no [mapa de relações narrativas](MAPA_RELACOES_NARRATIVAS.md). As origens abaixo são criações de design, e não classificações históricas do folclore. Atribuir Ferocidade a uma ave não é afirmar agressividade biológica; atribuir Seiva ao Corpo-Seco é uma associação visual com secura e madeira.

## 2. Regras gerais da proposta

1. **Lendária significa raridade 5, com custo proposto de 5 gold.** Ser personagem de uma lenda não torna automaticamente a unidade lendária. Uma planta ou ave também pode ocupar essa raridade.
2. **Raridade, estrelas e patamar são independentes.** Raridade define custo e faixa de poder; estrelas evoluem uma unidade; patamares contam identidades diferentes com a mesma origem.
3. Contam apenas unidades colocadas no campo no início do combate. Banco, invocações e cópias adicionais da mesma identidade não aumentam a contagem.
4. Os patamares são **substitutivos**: seis integrantes de Vigília recebem o efeito de seis, não a soma de dois, quatro e seis.
5. As contagens ficam fixadas no início do combate. A morte de uma unidade não derruba o patamar no meio da luta. Apenas sobreviventes podem produzir novos efeitos.
6. Cada origem beneficia **seus próprios integrantes**, inclusive cópias, salvo o efeito indireto de uma marca sobre inimigos. Não há bônus global implícito para todo o time.
7. Duas origens podem coexistir na mesma unidade. Aumentos da mesma grandeza são somados; grandezas diferentes seguem etapas distintas do cálculo. Aumento de ataque não é a mesma coisa que aumento de dano final.
8. Todos os acúmulos, escudos e cargas descritos aqui acabam junto com o combate. Não há crescimento permanente, geração de gold ou recompensa por comprar e vender unidades.
9. Os números são pontos iniciais para protótipo. A consistência de contagem foi conferida; a força em combate ainda precisa de simulação e teste jogável.

### Por que usar três sequências diferentes?

| Sequência | Uso nesta proposta | Motivo |
| --- | --- | --- |
| **2/4/6/8** | Vigília, Travessia, Ferocidade, Assombro e Encanto | Permite começar com uma dupla, combinar duas origens em quatro ou seis membros e chegar a oito deixando uma vaga livre. |
| **3/6/9** | Seiva, Correnteza e Vozes | Exige um núcleo real; seis integrantes definem a composição; nove exigem compromisso total com a origem. |
| **1/2/3/4** | Fulgor | Conjunto de abertura de combate. Uma unidade recebe benefício pequeno apenas para si; quatro criam uma abertura forte, com cinco vagas disponíveis para defesa, dano e apoio. |

Nenhum patamar exige dez peças, emblema, invocação ou cópia contada duas vezes. Há exemplos completos de nove unidades alcançando o último patamar de cada origem na seção 8.

## 3. As nove origens e seus efeitos

### Disponibilidade no catálogo

| Origem | Integrantes disponíveis | Patamares |
| --- | ---: | --- |
| Seiva | 14 | 3/6/9 |
| Correnteza | 14 | 3/6/9 |
| Vozes | 12 | 3/6/9 |
| Vigília | 20 | 2/4/6/8 |
| Travessia | 17 | 2/4/6/8 |
| Ferocidade | 17 | 2/4/6/8 |
| Assombro | 17 | 2/4/6/8 |
| Encanto | 14 | 2/4/6/8 |
| Fulgor | 7 | 1/2/3/4 |

As 132 atribuições correspondem a duas origens por unidade. Ter vinte opções de Vigília não significa colocar vinte peças: permite escolher oito com funções e raridades diferentes.

**Convenções:** vida máxima é a vida da unidade beneficiada; mana não pode exceder o máximo; efeitos periódicos começam depois do intervalo indicado, nunca no instante zero. Cura não ressuscita. Escudos expiram no prazo informado.

### Seiva — crescer, sustentar e continuar

**Relação:** plantas, sementes, regeneração e continuidade. Mutum-de-alagoas aproxima conservação e retorno; Corpo-Seco oferece uma leitura contrastante de corpo e madeira.  
**Patamares: 3/6/9.**

A cada **4 segundos**, cada integrante vivo se cura e recebe um acúmulo de Crescimento, até três acúmulos.

| Integrantes | Cura por pulso | Cada acúmulo de Crescimento | Máximo após três pulsos |
| --- | --- | --- | --- |
| 3 | 2% da vida máxima | +2% ao dano, cura e escudos das próprias ações | +6% |
| 6 | 3% da vida máxima | +4% ao dano, cura e escudos das próprias ações | +12% |
| 9 | 5% da vida máxima | +7% ao dano, cura e escudos das próprias ações | +21% |

Crescimento amplifica ataques e habilidades da unidade, mas **não amplifica os pulsos, escudos ou outros efeitos produzidos pelas próprias origens**. Evita retroalimentação da cura.

**Como jogar contra:** pressionar antes de 12 segundos, atingir os causadores de dano e reduzir cura. Seiva não fornece um escudo inicial capaz de anular a abertura adversária.

### Vigília — preservar, resistir e impor limites

**Relação:** guardiões narrativos, formas de abrigo e respostas defensivas. Não exige que todos os integrantes sejam Tanks.  
**Patamares: 2/4/6/8.**

Uma vez por combate, quando um integrante vai cair abaixo de **50% de vida**, recebe um escudo por **4 segundos**. O escudo entra antes da aplicação desse golpe, podendo absorver parte dele; não garante sobrevivência.

| Integrantes | Escudo | Redução da duração de controle enquanto o escudo existir |
| --- | --- | --- |
| 2 | 8% da vida máxima | 10% |
| 4 | 14% da vida máxima | 15% |
| 6 | 20% da vida máxima | 25% |
| 8 | 28% da vida máxima | 35% |

A resistência reduz duração de controles temporários, não distância de deslocamento nem dano. O bônus termina quando o escudo acaba ou expira.

**Como jogar contra:** consumir os escudos e retomar a pressão; buscar unidades frágeis que continuam tendo pouca vida base.

### Correnteza — circular, acumular e devolver

**Relação:** águas de diferentes escalas, margens, reservatórios vegetais e seres ligados ao desconhecido submerso. Não afirma convivência de espécies ou identidade entre águas doces e marinhas.  
**Patamares: 3/6/9.**

A cada **5 segundos**, todos os integrantes vivos recebem uma onda individual de mana e escudo.

| Integrantes | Mana por onda | Escudo por 2 segundos |
| --- | --- | --- |
| 3 | 6 | 3% da vida máxima |
| 6 | 10 | 5% da vida máxima |
| 9 | 16 | 8% da vida máxima |

Escudos de ondas sucessivas não se somam; uma nova aplicação substitui o restante pelo maior valor e renova a duração. Não há cura nem controle de grupo automático.

**Como jogar contra:** aproveitar os intervalos entre ondas e interromper os conjuradores. Dano contínuo ganha janelas de três segundos sem o escudo periódico.

### Vozes — anunciar, chamar e fazer circular

**Relação:** canto, assobio, dança, grito e história que passa de pessoa para pessoa. Palmito-juçara entra como vínculo interpretativo com aves e alimento, não por emitir voz.  
**Patamares: 3/6/9.**

Quando um integrante conclui uma habilidade, envia um Eco a até **dois outros integrantes de Vozes**, os mais próximos dentro de **dois hexágonos**.

| Integrantes | Mana recebida por cada destinatário |
| --- | --- |
| 3 | 4 |
| 6 | 7 |
| 9 | 11 |

Um emissor pode produzir um Eco a cada **4 segundos**; um destinatário só pode receber um Eco a cada **2 segundos**, independentemente da quantidade de emissores. Cópias da mesma identidade compartilham o intervalo de emissão. Não há autoalimentação, e a concessão de mana não é um lançamento de habilidade. Uma habilidade interrompida antes de concluir não produz Eco.

**Como jogar contra:** separar a formação, alcançar os suportes e explorar o agrupamento com dano em área. O conjunto tem apenas um Tank natural, Tutu-Marambá; nove Vozes é uma composição deliberadamente frágil e exige encontrá-lo.

### Ferocidade — insistir até abrir uma brecha

**Relação:** vigor corporal, ataques sucessivos e presença animal ou monstruosa. O nome é de combate, sem transformar animais reais em seres moralmente violentos.  
**Patamares: 2/4/6/8.**

Cada ataque básico que acerta concede um acúmulo de Ímpeto ao atacante, até oito. A cada terceiro ataque básico acertado, ele recupera vida.

| Integrantes | Ataque por acúmulo | Ataque máximo adicional | Cura a cada terceiro ataque |
| --- | --- | --- | --- |
| 2 | +1,5% | +12% | 1% da vida máxima |
| 4 | +2,5% | +20% | 1,5% da vida máxima |
| 6 | +3,5% | +28% | 2% da vida máxima |
| 8 | +5% | +40% | 3% da vida máxima |

Conta um ataque, não cada projétil ou alvo de um ataque múltiplo. Habilidades não geram acúmulos. Trocar de alvo mantém os acúmulos; morrer os encerra. O ganho de ataque é calculado sobre o ataque anterior aos bônus temporários, sem juros compostos.

**Como jogar contra:** desarmar, reduzir velocidade de ataque ou eliminar a unidade antes dos oito acertos. Um Tank continua partindo de ataque baixo; a origem não lhe dá o ataque base de um Atacante.

### Travessia — seguir sinais, mudar de caminho e encontrar

**Relação:** rastros, desorientação, viagens, perseguição e encontros inesperados.  
**Patamares: 2/4/6/8.**

Ao adquirir um alvo pela primeira vez ou mudar para outra identidade de alvo, um integrante recebe movimento por 2 segundos e prepara um único golpe de aproximação.

| Integrantes | Velocidade de movimento | Dano adicional do golpe de aproximação |
| --- | --- | --- |
| 2 | +12% | +10% |
| 4 | +20% | +16% |
| 6 | +30% | +24% |
| 8 | +45% | +35% |

O bônus de dano é consumido no primeiro ataque ou primeiro impacto de habilidade contra o novo alvo, dentro de 4 segundos. Não afeta todos os alvos de uma área nem todos os impactos de uma sequência. Intervalo de ativação: **4 segundos por unidade**. Reaquisição da mesma identidade após uma interrupção não conta como troca.

**Como jogar contra:** manter uma frente organizada, oferecer alvos resistentes na rota e proteger unidades frágeis. A origem não concede salto, teletransporte, troca de alvo forçada ou invulnerabilidade.

### Assombro — tornar o conhecido ameaçador

**Relação:** aparições, corpo impossível, medo doméstico e ameaça que se conta.  
**Patamares: 2/4/6/8.**

Ao acertar um inimigo com ataque ou habilidade de dano, o integrante aplica uma marca por **4 segundos**, reduzindo as duas defesas do alvo.

| Integrantes | Redução de armadura e resistência mágica |
| --- | --- |
| 2 | 6% |
| 4 | 10% |
| 6 | 15% |
| 8 | 22% |

Cada emissor só pode reaplicar ao mesmo alvo após **6 segundos**. Marcas da origem não se somam: vale a maior redução ativa. A redução só age sobre defesas positivas; não torna uma defesa negativa mais negativa. Qualquer aliado pode aproveitar a defesa reduzida do inimigo, mesmo sem Assombro.

**Como jogar contra:** impedir a aplicação inicial, limpar a marca ou explorar o intervalo sem reaplicação. É a principal ponte entre atacantes físicos e conjuradores mágicos.

### Encanto — a primeira aparência prepara a revelação

**Relação:** transformação, sedução, reflexo, fascínio e ornamento. Flores entram por uma associação visual declaradamente criativa.  
**Patamares: 2/4/6/8.**

Após concluir uma habilidade, o integrante prepara a própria **próxima habilidade**.

| Integrantes | Aumento no dano, cura e escudos da próxima habilidade |
| --- | --- |
| 2 | +8% |
| 4 | +14% |
| 6 | +22% |
| 8 | +32% |

Existe no máximo uma carga por unidade. A primeira habilidade não recebe esse bônus; a carga é consumida no início da seguinte e renovada quando ela termina. Uma interrupção pode desperdiçar a carga. Não aumenta duração de controle, tamanho de aura, geração de mana, defesa ou percentuais de buffs.

Para um Porradeiro cuja habilidade apenas amplifica o próprio ataque, Encanto não aumenta automaticamente essa amplificação: a unidade contribui à contagem, mas só aproveita o bônus se sua habilidade possuir dano, cura ou escudo explícito. Isso deve aparecer na descrição de sua ficha.

**Como jogar contra:** impedir o segundo lançamento, interromper habilidades e alcançar os integrantes mais frágeis.

### Fulgor — o primeiro clarão

**Relação:** luz que avisa, fascina ou ameaça; Ipê-amarelo participa pela imagem dourada, sem alegar que a planta produza fogo.  
**Patamares: 1/2/3/4.**

No começo do combate, cada integrante recebe mana inicial extra e fortalece a primeira habilidade iniciada.

| Integrantes | Mana inicial extra | Dano, cura e escudos da primeira habilidade |
| --- | --- | --- |
| 1 | +5 | +8% |
| 2 | +10 | +12% |
| 3 | +18 | +18% |
| 4 | +28 | +25% |

O bônus de potência não amplia controle, aura, geração de mana ou percentuais de buffs. A carga é consumida no início da primeira habilidade, mesmo que ela seja interrompida ou não tenha componente elegível. O bônus cobre os efeitos desse único lançamento; não é renovado por seus vários impactos.

**Por que permitir uma unidade:** ela recebe apenas uma pequena vantagem pessoal. Colocar um João Galafuz isolado não acelera os outros oito integrantes do time.

**Como jogar contra:** absorver a abertura com uma frente resistente e levar a luta para além do primeiro lançamento.

### Regras para combinações de efeitos

- Buffs percentuais na mesma grandeza se somam. Seiva e Encanto, quando aplicáveis à mesma habilidade, somam seus percentuais de potência.
- Aumento de ataque e aumento do dano de um impacto atuam em etapas diferentes. Essa interação faz Ferocidade + Travessia funcionar, mas precisa ser testada contra alvos frágeis.
- Uma instância de escudo não cura nem gera mana por ser aplicada. A soma de escudos ativos fica limitada a **40% da vida máxima** do destinatário nesta proposta.
- Redução percentual de defesas por efeitos diferentes é aditiva e limitada a **30%**. A redução de duração de controle fica limitada a **50%**.
- Auras com o mesmo benefício numérico usam o maior valor, sem soma. Benefícios distintos podem coexistir. Reaplicar não cria cópias de uma aura.
- Controle forte sugerido para habilidades tem duração inicial máxima de **1 segundo**; após terminar, o alvo recebe **0,75 segundo** de imunidade a novo controle forte. Empurrões também respeitam essa janela. Lentidão não é controle forte.
- Dano, cura, escudo ou mana produzidos por origens não disparam outras origens. Apenas ações elegíveis de unidades o fazem.

## 4. Funções de combate

| Função | Ataques e crescimento | Resistência e posicionamento | Habilidade característica |
| --- | --- | --- | --- |
| **Tank** | Baixo dano por ataque; evolução privilegia vida, armadura e resistência mágica. | Alta vida e defesa; segura a frente. | Defesa própria, escudo, provocação ou controle. |
| **Conjurador** | Ataques fracos; evolução privilegia dano de habilidade. | Vida e defesas baixas; normalmente atrás da frente. | Grande dano mágico em área ou concentrado, sustentado pela mana. |
| **Atacante** | Ataques tornam-se mais perigosos com cadência e acúmulos. | Vida e defesas baixas; precisa de tempo protegido. | Amplifica o próprio ataque ou velocidade de ataque. |
| **Assassino** | Dano concentrado em uma janela; não precisa vencer em dano sustentado. | Pouca vida e defesa; entra por abertura. | Explosão de dano contra alvo vulnerável. |
| **Suporte** | Pouco dano de ataque; crescimento privilegia utilidade. | Pouca vida e defesa; protegido, mas perto de quem recebe a aura. | Buffs/debuffs e aura nos hexágonos ao redor. |
| **Porradeiro** | Ataques fortes desde cedo; evolução preserva ataque e resistência. | Boa vida e defesa; permanece na luta próxima. | Buff em si mesmo: ataque, resistência, recuperação ou combinação limitada. |

O custo e as estrelas escalam a unidade **dentro dessa identidade**. Aumentar raridade não converte um Suporte em Tank nem um Tank em Atacante. A forma física também não determina função: Boiúna é grande e frágil; Anta Bondosa continua Suporte; árvores podem ser Conjuradores.

**Suportes:** todas as fichas incluem aura de raio de **um hexágono**, medida por distância hexagonal. A aura acompanha a unidade; plantas imóveis exigem posicionamento inicial. A aura afeta outros aliados ou inimigos elegíveis nos hexágonos vizinhos, não o próprio emissor, salvo efeito pessoal explicitamente descrito. Saiu da área ou morreu o emissor, termina o efeito contínuo. Escudos já concedidos conservam sua duração. Melhorias de aura das habilidades duram 4 segundos por padrão.

**Assassinos:** a habilidade procura, entre alvos alcançáveis pelo seu alcance e movimento definidos, o inimigo com menor percentual de vida; desempata por menor vida absoluta e depois distância. A seleção fica travada durante o início da habilidade. Estar vulnerável não concede acesso irrestrito ao outro lado do tabuleiro; cada salto precisa de alcance próprio. Ataques comuns podem atingir o alvo próximo até existir oportunidade de habilidade.

**Posicionamento regional:** Tanks e Porradeiros fazem a frente; Atacantes e Conjuradores ficam protegidos; Suportes ocupam casas que cobrem ao menos dois aliados quando possível; Assassinos buscam os flancos. Não é necessário agrupar todos ao redor de uma única aura.

## 5. Catálogo completo de 66 unidades

O custo é igual à raridade proposta. **★ Lendária** indica raridade 5, sem relação com o número de estrelas de evolução. Os conceitos de habilidade abaixo são novos desenhos de comportamento, não descrições de funcionalidades já implementadas. Adaptações de animais e plantas são fantásticas.

### 45 unidades já presentes no projeto

| Unidade | Custo / raridade | Função | Origens novas | Conceito de habilidade e comportamento |
| --- | --- | --- | --- | --- |
| Aguapé | 2 | Suporte | Seiva + Correnteza | Aura nos hexágonos adjacentes cura aliados; a habilidade reforça essa cura por 4 s. |
| Alamoa | 5 — ★ Lendária | Conjurador | Encanto + Fulgor | Concentra um clarão numa área após breve aviso; ataques fracos, grande dano de habilidade. |
| Anhangá | 3 | Tank | Vigília + Travessia | Recebe escudo próprio e provoca inimigos próximos; cresce em vida e resistências. |
| Arara-azul-de-lear | 2 | Atacante | Vozes + Ferocidade | Ataques consecutivos acumulam velocidade; a habilidade acelera os próprios disparos. |
| Ararinha-azul | 5 — ★ Lendária | Suporte | Vozes + Vigília | Aura adjacente concede resistência a controle; a habilidade amplia escudos nos aliados da aura. |
| Araucária | 5 — ★ Lendária | Tank | Seiva + Vigília | Endurece o próprio tronco e enraíza inimigos próximos; pouco dano por ataque. |
| Boiúna | 5 — ★ Lendária | Conjurador | Correnteza + Assombro | Uma onda sombria percorre uma faixa e causa grande dano mágico; corpo grande sem defesa de Tank. |
| Brinco-de-princesa | 1 | Conjurador | Seiva + Encanto | Acumula energia floral e detona pétalas numa pequena área; ataque básico fraco. |
| Bromélia | 1 | Suporte | Seiva + Correnteza | Aura adjacente melhora a cura recebida; a habilidade distribui água e escudo nessa aura. |
| Caapora | 4 | Atacante | Vigília + Ferocidade | Disparos sucessivos fortalecem o próprio ataque; a habilidade sustenta a sequência ofensiva. |
| Cabeça-de-Cuia | 3 | Porradeiro | Correnteza + Assombro | Golpes pesados; a habilidade concede a si roubo de vida de ataques e resistência temporária. |
| Capivara | 1 | Tank | Correnteza + Vigília | Assume postura defensiva, recebe escudo e interrompe brevemente inimigos junto ao corpo. |
| Caranguejo Uçá | 2 | Tank | Correnteza + Vigília | Fecha a guarda e prende um inimigo próximo; cresce em defesa, não em dano de pinça. |
| Comadre Fulozinha | 4 | Conjurador | Vozes + Vigília | Assobio concentra dano mágico em área; controle secundário curto, ataques fracos. |
| Corpo-Seco | 4 | Atacante | Assombro + Seiva | Cada ataque acumula vigor ofensivo; a habilidade amplifica os próprios ataques, sem vida de Tank. |
| Cumacanga | 2 | Conjurador | Assombro + Fulgor | Lança a chama da cabeça numa área; a explosão da habilidade concentra seu dano. |
| Guaraná | 1 | Suporte | Seiva + Encanto | Aura adjacente concede pequena velocidade de ataque; habilidade reforça o benefício por 4 s. |
| Ipê-amarelo | 2 | Conjurador | Seiva + Fulgor | Explosão de flores douradas causa dano mágico em área; troca a antiga vocação defensiva por magia. |
| Jararaca | 2 | Assassino | Ferocidade + Travessia | Escolhe alvo vulnerável alcançável e concentra veneno numa mordida de habilidade; frágil após o bote. |
| Labatut | 3 | Porradeiro | Assombro + Ferocidade | Ataques fortes; a habilidade aumenta o próprio ataque e resistência durante a luta próxima. |
| Lobo-guará | 5 — ★ Lendária | Atacante | Ferocidade + Travessia | Acumula velocidade com ataques; a habilidade acelera a própria sequência. Sem comando de alcateia. |
| Mãe-D'Água | 5 — ★ Lendária | Suporte | Correnteza + Encanto | Aura adjacente sustenta cura; habilidade protege os aliados na aura com escudo. Continua frágil. |
| Mãe De Ouro | 3 | Conjurador | Fulgor + Encanto | Concentra brilho e detona ouro ilusório numa área; não gera moeda nem renda. |
| Mandacaru | 1 | Tank | Seiva + Vigília | Endurece a própria estrutura e reduz dano recebido; espinhos apenas complementam a defesa. |
| Mapinguari | 5 — ★ Lendária | Porradeiro | Ferocidade + Vigília | Ataques pesados e corpo resistente; habilidade amplia o próprio ataque e recuperação de vida. |
| Matinta Perera | 3 | Assassino | Vozes + Travessia | Assobia sobre um alvo vulnerável e desfere uma explosão concentrada; sem dano sustentado de Atacante. |
| Mboi-Guaçu | 5 — ★ Lendária | Porradeiro | Correnteza + Ferocidade | Fortalece o próprio corpo e mordidas; não depende de fogo para se distinguir da Boiúna. |
| Minhocão | 3 | Tank | Correnteza + Travessia | Abala o chão, interrompe inimigos e ganha defesa própria; ataque básico de baixo impacto. |
| Mutum-de-alagoas | 5 — ★ Lendária | Atacante | Vozes + Seiva | Ataques acumulam ritmo; habilidade aumenta o próprio ataque e velocidade. Passa a ser fonte de dano sustentado. |
| Onça-pintada | 4 | Assassino | Ferocidade + Travessia | Bote de habilidade em alvo vulnerável, com explosão de dano; pouca resistência após entrar. |
| Palmito-juçara | 2 | Atacante | Seiva + Vozes | Dispara sementes numa adaptação fantástica; ataques acumulados e habilidade ampliam a própria cadência. |
| Papa Figo | 2 | Suporte | Assombro + Encanto | Aura adjacente enfraquece o ataque inimigo; habilidade aumenta o enfraquecimento, sem explosão de dano. |
| Pau Brasil | 4 | Porradeiro | Seiva + Vigília | Golpes fortes de madeira; habilidade aumenta o próprio ataque e endurece o corpo. |
| Pé-de-Garrafa | 5 — ★ Lendária | Assassino | Travessia + Assombro | Segue um alvo vulnerável e desfere pisão de habilidade explosivo; depende de encontrar abertura. |
| Pequi | 1 | Suporte | Seiva + Vigília | Aura adjacente concede pequena defesa; habilidade cura aliados dentro da aura. |
| Pisadeira | 5 — ★ Lendária | Assassino | Assombro + Travessia | Cai sobre o alvo vulnerável, causa grande dano de habilidade e breve interrupção. |
| Quibungo | 3 | Porradeiro | Assombro + Ferocidade | Mordidas fortes; habilidade concede a si ataque e recuperação por ataques durante poucos segundos. |
| Romãozinho | 5 — ★ Lendária | Assassino | Assombro + Vozes | Marca a vítima mais vulnerável e explode a marca com a habilidade; a travessura é visual, não economia. |
| Sabiá Laranjeira | 1 | Suporte | Vozes + Encanto | Aura de canto nos hexágonos adjacentes aumenta ataque aliado; habilidade intensifica a canção. |
| Sumaúma | 4 | Tank | Seiva + Vigília | Ganha grande escudo próprio e prende inimigos junto às raízes; cresce em vida e defesa. |
| Tamanduá bandeira | 2 | Porradeiro | Ferocidade + Vigília | Golpes fortes de garra; habilidade fortalece o próprio ataque e resistência. |
| Tatu-bola-do-nordeste | 1 | Tank | Vigília + Travessia | Enrola o corpo para reduzir dano e interromper o inimigo mais próximo; ataque baixo. |
| Teiniaguá | 3 | Conjurador | Encanto + Fulgor | Condensa brilho numa explosão mágica; pouco dano por ataque e pouca resistência. |
| Tutu-Marambá | 5 — ★ Lendária | Tank | Assombro + Vozes | Amplifica a própria defesa e assusta inimigos próximos por pouco tempo; não é carregador de dano. |
| Vitória-régia | 2 | Suporte | Seiva + Correnteza | Aura adjacente concede escudo pequeno periódico; habilidade reforça a proteção nos aliados próximos. |

### 21 candidatas pesquisadas

| Unidade | Custo / raridade | Função | Origens novas | Conceito de habilidade e comportamento |
| --- | --- | --- | --- | --- |
| Anta Bondosa | 2 | Suporte | Vigília + Travessia | Aura adjacente favorece recuperação; habilidade socorre aliados nela. Tamanho não implica resistência de Tank. |
| Bebê-Diabo | 1 | Conjurador | Assombro + Vozes | Grito de habilidade causa dano mágico numa pequena área; ataques fracos e baixa vida. |
| Boi Misterioso | 5 — ★ Lendária | Porradeiro | Ferocidade + Travessia | Chifradas fortes e corpo resistente; habilidade aumenta o próprio ataque e defesa. Lendária de dano sustentado na frente. |
| Boitatá | 4 | Conjurador | Vigília + Fulgor | Faixa de fogo sinalizada causa grande dano de habilidade; pouca resistência apesar do tema de proteção. |
| Boto Encantado | 3 | Suporte | Correnteza + Encanto | Aura adjacente reduz dano aliado; transformação reforça os escudos dentro da aura. |
| Caboclo d'Água do São Francisco | 3 | Tank | Correnteza + Vigília | Ganha defesa própria e interrompe inimigos próximos com uma onda curta. |
| Cabra Cabriola | 2 | Porradeiro | Assombro + Ferocidade | Cabeçadas fortes; habilidade aumenta o próprio ataque e resistência, com controle apenas secundário. |
| Capelobo | 4 | Porradeiro | Ferocidade + Travessia | Fortalece garras e o próprio corpo; permanece na frente para sustentar ataques pesados. |
| Capeta do Vilarinho | 4 | Suporte | Encanto + Vozes | Aura adjacente de dança acelera aliados; habilidade intensifica a aura e atrapalha inimigos nela. |
| Chupa-Cabra | 3 | Assassino | Ferocidade + Assombro | Habilidade concentra dano sobre alvo vulnerável e recupera pequena vida própria; frágil fora da abertura. |
| Curupira | 3 | Suporte | Vigília + Travessia | Aura de pegadas nos hexágonos adjacentes desacelera inimigos; habilidade concede resistência a aliados nela. |
| Ipupiara | 4 | Porradeiro | Correnteza + Ferocidade | Golpes pesados; habilidade amplia o próprio ataque e concede defesa temporária. |
| João Galafuz | 2 | Conjurador | Correnteza + Fulgor | Clarão marítimo explode após aviso curto; baixa vida e defesa. |
| Lobisomem do Sertão | 3 | Porradeiro | Ferocidade + Encanto | Transformação aumenta o próprio ataque, resistência e recuperação por ataques. |
| Loira do Banheiro | 3 | Conjurador | Assombro + Encanto | Espelho marcado explode em área após aviso; depende da habilidade para causar dano. |
| Loira do Bonfim | 3 | Assassino | Encanto + Travessia | Marca o alvo vulnerável para um encontro súbito e explosivo; mobilidade não concede longa invulnerabilidade. |
| Mãozão | 3 | Tank | Vigília + Travessia | Palmada desorienta inimigos próximos e concede defesa própria; ataque básico baixo. |
| Num-se-Pode | 4 | Tank | Assombro + Encanto | Cresce, aumenta a própria vida efetiva e interrompe inimigos próximos; não ganha ataque proporcional. |
| Pai do Mato | 3 | Tank | Vigília + Ferocidade | Fortalece a própria defesa e provoca inimigos próximos; protege pelo posicionamento e controle. |
| Perna Cabeluda | 2 | Atacante | Assombro + Travessia | Chutes acumulam ritmo; habilidade aumenta a própria cadência e ataque. Não é uma segunda assassina de pisão. |
| Saci-Pererê | 2 | Suporte | Vozes + Travessia | Aura adjacente de redemoinho reduz velocidade de ataque inimiga; habilidade reforça aliados na aura. |

### Mudanças importantes em relação aos desenhos anteriores

- **Ipê-amarelo:** Tank → Conjurador. Oferece dano mágico aos conjuntos de plantas e ao Cerrado.
- **Brinco-de-princesa:** Suporte → Conjurador. Evita que a abertura vegetal tenha apenas cura e defesa.
- **Palmito-juçara:** Suporte → Atacante. Cria uma opção acessível de dano sustentado em Seiva e Vozes.
- **Mutum-de-alagoas:** Suporte → Atacante lendário. Forma uma dupla complementar com a Araucária Tank.
- **Sabiá Laranjeira:** a função inferida atualmente pelo cadastro é Atacante; aqui fica explicitamente Suporte de aura.
- **Pequi:** a função inferida atualmente é Conjurador; aqui fica explicitamente Suporte defensivo.
- **Cumacanga:** a marca atual de Assassino dá lugar a Conjurador; a raridade proposta sobe de 1, herdada do valor padrão, para 2.
- **Perna Cabeluda:** a proposta anterior de Porradeiro passa a Atacante, sustentando chutes sucessivos.
- **Loira do Bonfim:** a proposta anterior de Suporte passa a Assassino, concentrando o encontro numa janela de dano.
- **Boi Misterioso:** a proposta anterior de Tank de custo 4 passa a **Porradeiro lendário de custo 5**. Ele garante uma lendária ofensiva para a Caatinga e oferece alternativa ao Lobo-guará no Cerrado.
- **Todos os Suportes:** precisam efetivamente possuir aura local, e não apenas uma cura de alvo único ou um rótulo de suporte.

São decisões propostas, não migrações já realizadas. A maioria das raridades existentes foi preservada, mas as antigas origens e classes não determinaram nenhuma nova atribuição.

## 6. Seis equipes regionais de nove unidades

As equipes são **formações completas de referência**, não exclusividades de loja. Cada uma contém duas lendárias, pelo menos dois Tanks, dano por ataques, dano por habilidade, um Assassino e apoio.

A ordem das linhas é apenas de apresentação do elenco, **não a ordem de entrada por round**. Uma futura progressão de campanha deve introduzir frente, apoio e dano antes de acrescentar as lendárias. Não se propõe colocar as nove unidades no primeiro round.

Na coluna de sinergias, **“5 → 4” significa cinco integrantes presentes e patamar quatro ativo**. Bônus de origens com contagem insuficiente não foram incluídos.

### Cerrado

**Plano de combate:** Resistir à abertura, acumular ataques e alcançar alvos expostos.

O cenário é ancorado por Pequi, Ipê-amarelo, Tamanduá e Lobo-guará. Pai do Mato e Boitatá entram pelo vínculo narrativo com proteção e limites; Boi Misterioso aproxima viagem e vigor corporal. Tatu e Jararaca completam a composição sem exigir exclusividade regional.

| Unidade | Função | Custo | Origens |
| --- | --- | ---: | --- |
| Tatu-bola-do-nordeste | Tank | 1 | Vigília + Travessia |
| Pequi | Suporte | 1 | Seiva + Vigília |
| Tamanduá bandeira | Porradeiro | 2 | Ferocidade + Vigília |
| Ipê-amarelo | Conjurador | 2 | Seiva + Fulgor |
| Jararaca | Assassino | 2 | Ferocidade + Travessia |
| Pai do Mato | Tank | 3 | Vigília + Ferocidade |
| Boitatá | Conjurador | 4 | Vigília + Fulgor |
| Lobo-guará ★ | Atacante | 5 | Ferocidade + Travessia |
| Boi Misterioso ★ | Porradeiro | 5 | Ferocidade + Travessia |

**Lendárias:** Lobo-guará e Boi Misterioso.  
**Distribuição:** 2 Tank; 2 Conjurador; 1 Atacante; 1 Assassino; 1 Suporte; 2 Porradeiro.

**Sinergias ativas:** Vigília 5 → **4**; Travessia 4 → **4**; Ferocidade 5 → **4**; Fulgor 2 → **2**.

**Afinidades ainda sem ativação:** Seiva 2/3.

**Posicionamento e papéis:** Tatu e Pai do Mato seguram a frente; Tamanduá e Boi Misterioso pressionam junto dela. Lobo-guará sustenta dano, Jararaca explora aberturas e Ipê/Boitatá garantem resposta mágica. Pequi é o único Suporte: sua posição precisa cobrir a frente sem expô-lo.

**Por que funciona:** Vigília segura a primeira queda de vida; Ferocidade recompensa ataques sucessivos; Travessia favorece novas aberturas. A composição não depende de cura abundante.

**Ponto vulnerável:** Eliminar Pequi, controlar Lobo-guará e evitar que os Porradeiros acumulem ataques.

### Caatinga

**Plano de combate:** Alternar defesa e lançamentos, sustentando o avanço do Boi Misterioso.

Mandacaru, as duas aves e o Caboclo d'Água conectam paisagem seca, águas e vida regional. Cabra Cabriola e Boi Misterioso entram pela leitura de repertórios populares. Matinta, Boto e João Galafuz são visitantes temáticos: voz, transformação e luz. Isso não apresenta o boto como fauna do São Francisco nem João Galafuz como uma lenda fluvial.

| Unidade | Função | Custo | Origens |
| --- | --- | ---: | --- |
| Mandacaru | Tank | 1 | Seiva + Vigília |
| Arara-azul-de-lear | Atacante | 2 | Vozes + Ferocidade |
| Cabra Cabriola | Porradeiro | 2 | Assombro + Ferocidade |
| João Galafuz | Conjurador | 2 | Correnteza + Fulgor |
| Matinta Perera | Assassino | 3 | Vozes + Travessia |
| Boto Encantado | Suporte | 3 | Correnteza + Encanto |
| Caboclo d'Água do São Francisco | Tank | 3 | Correnteza + Vigília |
| Ararinha-azul ★ | Suporte | 5 | Vozes + Vigília |
| Boi Misterioso ★ | Porradeiro | 5 | Ferocidade + Travessia |

**Lendárias:** Ararinha-azul e Boi Misterioso.  
**Distribuição:** 2 Tank; 1 Conjurador; 1 Atacante; 1 Assassino; 2 Suporte; 2 Porradeiro.

**Sinergias ativas:** Vigília 3 → **2**; Vozes 3 → **3**; Ferocidade 3 → **2**; Correnteza 3 → **3**; Fulgor 1 → **1**; Travessia 2 → **2**.

**Afinidades ainda sem ativação:** Seiva 1/3; Assombro 1/2; Encanto 1/2.

**Posicionamento e papéis:** Mandacaru e Caboclo fazem a frente; Cabra e Boi lutam próximos. Lear e João fornecem ataque contínuo e magia. Matinta ameaça alvos frágeis. Boto e Ararinha dão apoio local; a Ararinha deve ficar a até dois hexágonos de Lear ou Matinta quando possível.

**Por que funciona:** Vozes acelera a circulação de mana entre as três vozes; Correnteza abastece Boto, João e Caboclo. Ararinha protege, enquanto o Boi é a lendária ofensiva.

**Ponto vulnerável:** Separar as três Vozes, atravessar a frente e tirar Lear/João de combate antes que o Boi estabilize a luta.

### Mata Atlântica

**Plano de combate:** Proteger uma formação que cresce com o tempo e sustenta dois Atacantes.

Pau Brasil e Mutum fazem a ligação concreta de conservação discutida na pesquisa. As demais plantas constroem o ambiente. Tatu-bola é uma inclusão por função e afinidade com defesa, declaradamente não uma espécie escolhida para representar de forma exclusiva esse cenário.

| Unidade | Função | Custo | Origens |
| --- | --- | ---: | --- |
| Tatu-bola-do-nordeste | Tank | 1 | Vigília + Travessia |
| Brinco-de-princesa | Conjurador | 1 | Seiva + Encanto |
| Sabiá Laranjeira | Suporte | 1 | Vozes + Encanto |
| Bromélia | Suporte | 1 | Seiva + Correnteza |
| Jararaca | Assassino | 2 | Ferocidade + Travessia |
| Palmito-juçara | Atacante | 2 | Seiva + Vozes |
| Pau Brasil | Porradeiro | 4 | Seiva + Vigília |
| Araucária ★ | Tank | 5 | Seiva + Vigília |
| Mutum-de-alagoas ★ | Atacante | 5 | Vozes + Seiva |

**Lendárias:** Araucária e Mutum-de-alagoas.  
**Distribuição:** 2 Tank; 1 Conjurador; 2 Atacante; 1 Assassino; 2 Suporte; 1 Porradeiro.

**Sinergias ativas:** Vigília 3 → **2**; Travessia 2 → **2**; Seiva 6 → **6**; Encanto 2 → **2**; Vozes 3 → **3**.

**Afinidades ainda sem ativação:** Correnteza 1/3; Ferocidade 1/2.

**Posicionamento e papéis:** Tatu e Araucária formam a frente; Pau Brasil pressiona ao lado. Palmito-juçara e Mutum são os Atacantes; Brinco oferece magia; Jararaca ameaça a retaguarda. Sabiá e Bromélia cobrem a formação com auras, distribuídos para reduzir o risco de uma única explosão em área.

**Por que funciona:** Seis Seivas crescem durante a luta. Sabiá, Palmito e Mutum mantêm Vozes 3 e aproximam o núcleo de ataques da circulação de habilidades.

**Ponto vulnerável:** Explodir os Atacantes antes dos três pulsos de Crescimento, aplicar redução de cura ou atingir o agrupamento com área.

### Litoral

**Plano de combate:** Vencer pelos lançamentos seguintes, usando água e encantamento como ritmo.

Caranguejo, Ipupiara, João e Alamoa ancoram referências costeiras; Bromélia e Palmito aproximam vegetação. Mãe-D'Água entra pela identidade aquática da versão de jogo a desenvolver. Loira do Bonfim e Num-se-Pode são visitantes pela aparição e pelo encontro inesperado, não personagens historicamente transferidas de cidade.

| Unidade | Função | Custo | Origens |
| --- | --- | ---: | --- |
| Caranguejo Uçá | Tank | 2 | Correnteza + Vigília |
| Bromélia | Suporte | 1 | Seiva + Correnteza |
| Palmito-juçara | Atacante | 2 | Seiva + Vozes |
| João Galafuz | Conjurador | 2 | Correnteza + Fulgor |
| Loira do Bonfim | Assassino | 3 | Encanto + Travessia |
| Num-se-Pode | Tank | 4 | Assombro + Encanto |
| Ipupiara | Porradeiro | 4 | Correnteza + Ferocidade |
| Alamoa ★ | Conjurador | 5 | Encanto + Fulgor |
| Mãe-D'Água ★ | Suporte | 5 | Correnteza + Encanto |

**Lendárias:** Alamoa e Mãe-D'Água.  
**Distribuição:** 2 Tank; 2 Conjurador; 1 Atacante; 1 Assassino; 2 Suporte; 1 Porradeiro.

**Sinergias ativas:** Correnteza 5 → **3**; Fulgor 2 → **2**; Encanto 4 → **4**.

**Afinidades ainda sem ativação:** Vigília 1/2; Seiva 2/3; Vozes 1/3; Travessia 1/2; Assombro 1/2; Ferocidade 1/2.

**Posicionamento e papéis:** Caranguejo e Num-se-Pode fazem a frente; Ipupiara é o Porradeiro. Palmito sustenta ataques, João e Alamoa causam magia, Loira do Bonfim busca uma vítima. Bromélia e Mãe-D'Água cobrem aliados adjacentes.

**Por que funciona:** Fulgor antecipa os primeiros lançamentos de João e Alamoa. Correnteza oferece novas janelas de mana. Encanto 4 melhora os lançamentos seguintes de seus integrantes; Num-se-Pode aproveita apenas componentes de escudo ou cura que sua habilidade efetivamente tenha.

**Ponto vulnerável:** Interromper Alamoa, pressionar os suportes e ganhar antes de a composição repetir suas habilidades.

### Pantanal

**Plano de combate:** Circular entre alvos, combinando uma frente estável com duas ameaças de explosão.

Capivara, Mãozão, Anta Bondosa e Pé-de-Garrafa oferecem os vínculos regionais e narrativos tratados na pesquisa. Teiniaguá é visitante explicitamente associada ao Jarau em sua referência; Perna Cabeluda vem do repertório recifense. Aqui entram pelo encantamento e pela travessia. Mboi-Guaçu permanece uma versão artística a distinguir das demais grandes serpentes.

| Unidade | Função | Custo | Origens |
| --- | --- | ---: | --- |
| Capivara | Tank | 1 | Correnteza + Vigília |
| Aguapé | Suporte | 2 | Seiva + Correnteza |
| Perna Cabeluda | Atacante | 2 | Assombro + Travessia |
| Anta Bondosa | Suporte | 2 | Vigília + Travessia |
| Teiniaguá | Conjurador | 3 | Encanto + Fulgor |
| Mãozão | Tank | 3 | Vigília + Travessia |
| Onça-pintada | Assassino | 4 | Ferocidade + Travessia |
| Mboi-Guaçu ★ | Porradeiro | 5 | Correnteza + Ferocidade |
| Pé-de-Garrafa ★ | Assassino | 5 | Travessia + Assombro |

**Lendárias:** Mboi-Guaçu e Pé-de-Garrafa.  
**Distribuição:** 2 Tank; 1 Conjurador; 1 Atacante; 2 Assassino; 2 Suporte; 1 Porradeiro.

**Sinergias ativas:** Correnteza 3 → **3**; Vigília 3 → **2**; Assombro 2 → **2**; Travessia 5 → **4**; Fulgor 1 → **1**; Ferocidade 2 → **2**.

**Afinidades ainda sem ativação:** Seiva 1/3; Encanto 1/2.

**Posicionamento e papéis:** Capivara e Mãozão seguram a frente; Mboi-Guaçu avança como Porradeiro. Perna Cabeluda acumula ataques, Teiniaguá causa magia, Onça e Pé-de-Garrafa buscam vítimas. Aguapé e Anta apoiam a frente e os retornos ao alcance de suas auras.

**Por que funciona:** Travessia 4 fortalece a chegada a novos alvos. Assombro permite que as marcas da Perna e do Pé-de-Garrafa beneficiem também os ataques de Mboi-Guaçu e a magia da Teiniaguá.

**Ponto vulnerável:** Proteger alvos frágeis, oferecer alvos resistentes aos Assassinos e separar os atacantes móveis das auras.

### Amazônia

**Plano de combate:** Sustentar os grandes causadores de dano enquanto os guardiões preservam a frente.

Guaraná, Vitória-régia, Matinta e as grandes presenças da floresta e das águas dão o eixo. Comadre Fulozinha é uma visitante por voz e proteção, sem apagar seu registro pernambucano. As tradições não são apresentadas como pertencentes a um único povo.

| Unidade | Função | Custo | Origens |
| --- | --- | ---: | --- |
| Guaraná | Suporte | 1 | Seiva + Encanto |
| Vitória-régia | Suporte | 2 | Seiva + Correnteza |
| Anhangá | Tank | 3 | Vigília + Travessia |
| Matinta Perera | Assassino | 3 | Vozes + Travessia |
| Caapora | Atacante | 4 | Vigília + Ferocidade |
| Comadre Fulozinha | Conjurador | 4 | Vozes + Vigília |
| Sumaúma | Tank | 4 | Seiva + Vigília |
| Mapinguari ★ | Porradeiro | 5 | Ferocidade + Vigília |
| Boiúna ★ | Conjurador | 5 | Correnteza + Assombro |

**Lendárias:** Mapinguari e Boiúna.  
**Distribuição:** 2 Tank; 2 Conjurador; 1 Atacante; 1 Assassino; 2 Suporte; 1 Porradeiro.

**Sinergias ativas:** Seiva 3 → **3**; Vigília 5 → **4**; Travessia 2 → **2**; Ferocidade 2 → **2**.

**Afinidades ainda sem ativação:** Encanto 1/2; Correnteza 2/3; Vozes 2/3; Assombro 1/2.

**Posicionamento e papéis:** Anhangá e Sumaúma formam a frente; Mapinguari é o Porradeiro. Caapora sustenta ataques, Matinta explode alvos vulneráveis, Comadre e Boiúna oferecem magia. Guaraná e Vitória-régia posicionam suas auras para sustentar esse núcleo.

**Por que funciona:** Vigília protege os integrantes ligados à guarda; Seiva sustenta Guaraná, Vitória-régia e Sumaúma. Caapora e Mapinguari compartilham Ferocidade. Boiúna não precisa ativar Correnteza para funcionar como uma lendária de dano mágico.

**Ponto vulnerável:** Pressionar os suportes e controlar Mapinguari. As auras obrigam parte da formação a permanecer relativamente próxima.

## 7. As 19 alternativas que completam o uso das 66 unidades

As seis equipes somam **54 vagas**, mas repetem sete participações entre regiões: há **47 identidades distintas** nas formações principais. As **19 restantes** recebem abaixo uma troca concreta. Assim, nenhuma unidade pesquisada fica sem origem, função ou lugar numa composição.

Cada troca foi calculada **isoladamente** sobre a equipe principal. Não se deve aplicar várias linhas simultaneamente presumindo que as contagens continuem iguais. Todas as variantes abaixo continuam com nove identidades distintas, duas lendárias e pelo menos uma unidade de cada função; Tutu-Marambá é a única troca que muda a função da vaga.

| Unidade que entra | Região | Unidade que sai | Mudança nos patamares ativos |
| --- | --- | --- | --- |
| Cabeça-de-Cuia | Litoral | Ipupiara | Assombro: inativo → 2 |
| Corpo-Seco | Mata Atlântica | Palmito-juçara | Vozes: 3 → inativo Perde a rede de Vozes e aumenta a dependência do dano individual; não é uma troca neutra. |
| Cumacanga | Cerrado | Ipê-amarelo | Preserva todos os patamares ativos; muda habilidade e/ou custo. |
| Labatut | Caatinga | Cabra Cabriola | Preserva todos os patamares ativos; muda habilidade e/ou custo. |
| Mãe De Ouro | Pantanal | Teiniaguá | Preserva todos os patamares ativos; muda habilidade e/ou custo. |
| Minhocão | Pantanal | Mãozão | Preserva todos os patamares ativos; muda habilidade e/ou custo. |
| Papa Figo | Litoral | Bromélia | Assombro: inativo → 2 |
| Pisadeira | Pantanal | Pé-de-Garrafa | Preserva todos os patamares ativos; muda habilidade e/ou custo. |
| Quibungo | Caatinga | Cabra Cabriola | Preserva todos os patamares ativos; muda habilidade e/ou custo. |
| Romãozinho | Pantanal | Pé-de-Garrafa | Preserva todos os patamares ativos; muda habilidade e/ou custo. |
| Tutu-Marambá | Caatinga | Boi Misterioso | Travessia: 2 → inativo; Assombro: inativo → 2 Passa de 2 para 3 Tanks e de 2 para 1 Porradeiro. |
| Bebê-Diabo | Amazônia | Comadre Fulozinha | Assombro: inativo → 2 |
| Capelobo | Cerrado | Tamanduá bandeira | Preserva todos os patamares ativos; muda habilidade e/ou custo. |
| Capeta do Vilarinho | Mata Atlântica | Sabiá Laranjeira | Preserva todos os patamares ativos; muda habilidade e/ou custo. |
| Chupa-Cabra | Pantanal | Onça-pintada | Preserva todos os patamares ativos; muda habilidade e/ou custo. |
| Curupira | Pantanal | Anta Bondosa | Preserva todos os patamares ativos; muda habilidade e/ou custo. |
| Lobisomem do Sertão | Cerrado | Tamanduá bandeira | Preserva todos os patamares ativos; muda habilidade e/ou custo. |
| Loira do Banheiro | Litoral | João Galafuz | Fulgor: 2 → 1; Assombro: inativo → 2 |
| Saci-Pererê | Pantanal | Anta Bondosa | Preserva todos os patamares ativos; muda habilidade e/ou custo. |

**Exemplos de escolhas:** Mãe De Ouro por Teiniaguá muda a personagem sem mudar origem, função ou custo. Pisadeira por Pé-de-Garrafa preserva a estrutura das duas lendárias do Pantanal. Corpo-Seco por Palmito-juçara mantém Seiva, mas retira Vozes 3: esse preço deve ficar claro antes da troca.

## 8. Composições que alcançam os patamares máximos

As equipes regionais são exemplos variados; não precisam chegar todas ao último patamar. Estes exemplos demonstram que **cada patamar máximo é alcançável com nove unidades reais do catálogo proposto**, sem emblemas ou repetições artificiais.

| Origem e patamar | Integrantes da origem | Complemento até nove unidades |
| --- | --- | --- |
| Seiva 9 | Mandacaru; Guaraná; Ipê-amarelo; Brinco-de-princesa; Bromélia; Palmito-juçara; Pau Brasil; Araucária; Mutum-de-alagoas | Nenhum: compromisso de nove vagas. |
| Correnteza 9 | Capivara; Caranguejo Uçá; Aguapé; João Galafuz; Boto Encantado; Cabeça-de-Cuia; Ipupiara; Mboi-Guaçu; Boiúna | Nenhum: compromisso de nove vagas. |
| Vozes 9 | Bebê-Diabo; Sabiá Laranjeira; Arara-azul-de-lear; Palmito-juçara; Matinta Perera; Comadre Fulozinha; Capeta do Vilarinho; Ararinha-azul; Tutu-Marambá | Nenhum: compromisso de nove vagas. |
| Vigília 8 | Mandacaru; Pequi; Tamanduá bandeira; Anhangá; Caapora; Comadre Fulozinha; Boitatá; Mapinguari | Matinta Perera |
| Travessia 8 | Tatu-bola-do-nordeste; Anta Bondosa; Jararaca; Matinta Perera; Mãozão; Onça-pintada; Lobo-guará; Boi Misterioso | Teiniaguá |
| Ferocidade 8 | Arara-azul-de-lear; Tamanduá bandeira; Jararaca; Pai do Mato; Caapora; Onça-pintada; Lobo-guará; Boi Misterioso | Boto Encantado |
| Assombro 8 | Bebê-Diabo; Perna Cabeluda; Papa Figo; Labatut; Cumacanga; Loira do Banheiro; Pisadeira; Tutu-Marambá | Bromélia |
| Encanto 8 | Brinco-de-princesa; Guaraná; Sabiá Laranjeira; Boto Encantado; Mãe De Ouro; Loira do Bonfim; Num-se-Pode; Alamoa | Caranguejo Uçá |
| Fulgor 4 | Ipê-amarelo; João Galafuz; Teiniaguá; Boitatá | Capivara; Caranguejo Uçá; Boto Encantado; Caapora; Lobo-guará |

### Exemplos de evolução das composições

- **Seiva 3:** Mandacaru, Guaraná e Ipê-amarelo. **Seiva 6:** acrescentar Brinco-de-princesa, Bromélia e Palmito-juçara. **Seiva 9:** acrescentar Pau Brasil, Araucária e Mutum-de-alagoas. Há defesa, suporte e dano desde o primeiro núcleo; o fim depende de duas lendárias.
- **Vigília 2:** Mandacaru e Pequi. **Vigília 4:** acrescentar Tamanduá e Anhangá. **Vigília 6:** acrescentar Caapora e Comadre. **Vigília 8:** acrescentar Boitatá e Mapinguari. Matinta pode ocupar a nona vaga para oferecer explosão e Travessia 2 com Anhangá.
- **Fulgor 1:** Ipê-amarelo. **Fulgor 2:** acrescentar João Galafuz. **Fulgor 3:** acrescentar Teiniaguá. **Fulgor 4:** acrescentar Boitatá. Os outros cinco lugares precisam trazer frente, apoio e dano por ataques.

Essas sequências são caminhos de montagem por quantidade de peças, não promessa de acesso a cada raridade num nível específico de loja.

### Custos de se especializar

- **Seiva 9:** ocupa todas as vagas e não possui Assassino entre seus integrantes. Compensa pelo crescimento de uma formação protegida.
- **Correnteza 9:** não possui Atacante nem Assassino próprios neste catálogo. O dano vem de Conjuradores e Porradeiros, com dependência maior de mana.
- **Vozes 9:** Tutu-Marambá é o único Tank disponível; procurá-lo é parte do custo de fechar a origem. A formação ainda precisa posicionar vozes dentro do alcance do Eco.
- **Vigília 8:** protege muitos membros, mas não elimina a necessidade de fontes reais de dano.
- **Travessia 8:** muitos membros querem oportunidades de alvo; funciona pior quando todos ficam presos numa frente resistente.
- **Ferocidade 8:** o exemplo tem apenas um Tank e usa a nona vaga para um Suporte. Predomina dano de ataques; defesas físicas e redução de velocidade são respostas importantes.
- **Assombro 8:** a marca abre defesas, mas não substitui atributos ofensivos. Vários membros continuam frágeis.
- **Encanto 8:** a composição depende do segundo lançamento e reúne muitos usuários de habilidades; o exemplo usa a nona vaga como segundo Tank.
- **Fulgor 4:** os sete integrantes possíveis são Conjuradores nesta versão. Escolher quatro exige quatro vagas frágeis de dano mágico. O benefício de abertura não resolve essa fragilidade.

## 9. Sinergias entre origens e entre unidades

Estas combinações **usam os efeitos já definidos**, sem bônus secretos por dupla ou por nome de personagem.

| Combinação | Interação concreta | Exemplos | Limite ou resposta |
| --- | --- | --- | --- |
| **Seiva + Vigília** | O escudo de emergência cria tempo para os pulsos de crescimento. | Araucária, Pau Brasil, Sumaúma e Mandacaru; equipe da Mata Atlântica. | Escudo é único; foco e redução de cura interrompem o plano. |
| **Correnteza + Encanto** | As ondas de mana ajudam a chegar ao segundo lançamento, que já recebe Encanto. | Boto e Mãe-D'Água; equipe do Litoral. | As contagens precisam ser ativadas separadamente. Ter apenas Boto não ativa nenhuma das duas. |
| **Vozes + Encanto** | Lançamentos alimentam colegas, e novas habilidades recebem potência de Encanto. | Sabiá, Capeta do Vilarinho e os demais membros de cada núcleo. | Intervalos de emissão e recepção do Eco impedem cascatas instantâneas; agrupamento tem risco. |
| **Fulgor + Encanto** | Fulgor fortalece o primeiro lançamento; Encanto fortalece os seguintes. | Alamoa, Teiniaguá e Mãe De Ouro. | Uma unidade isolada só ativa Fulgor 1; Encanto precisa de pelo menos duas identidades. |
| **Assombro + Travessia** | Uma marca de defesa aberta pode preparar a explosão contra um novo alvo. | Perna Cabeluda e Pé-de-Garrafa; Onça pode aproveitar a defesa reduzida. | A marca não aumenta o golpe que a aplicou: o debuff entra após resolver o dano daquele impacto. |
| **Ferocidade + Vigília** | Sobreviver à primeira pressão permite acumular ataques. | Caapora, Mapinguari e Tamanduá. | Um escudo não torna seguro permanecer cercado; controle reduz o acúmulo. |
| **Ferocidade + Travessia** | O ataque acumulado sustenta pressão, e a troca de alvo oferece um pico limitado. | Lobo-guará, Onça, Jararaca e Boi Misterioso. | Só um impacto recebe o bônus de aproximação, com intervalo de quatro segundos. |
| **Vozes + Seiva** | A formação cresce e lança habilidades com mais frequência, preservando dano por ataques. | Palmito-juçara e Mutum, acompanhados por Sabiá e plantas. | Remover Palmito da equipe principal da Mata desativa Vozes 3. |

### Encontros narrativos preservados na mecânica

- **Matinta + Comadre + Sabiá:** três modos de anunciar uma presença tornam-se Vozes 3. São Assassino, Conjurador e Suporte: compartilham afinidade sem repetir papel.
- **Mãe De Ouro + Teiniaguá + Alamoa:** três aparições luminosas ativam Fulgor 3 e Encanto 2. Abrem forte e melhoram lançamentos seguintes, mas precisam de frente.
- **Mutum + Pau Brasil + Araucária:** ativam Seiva 3; Pau Brasil e Araucária também ativam Vigília 2. Atacante, Porradeiro e Tank formam um núcleo funcional.
- **Mãozão + Anta Bondosa + Curupira:** ativam Vigília 2 e Travessia 2. A relação entre desorientação e amparo vira controle e sustentação; ainda falta fonte de dano.
- **Bromélia + Vitória-régia + Boiúna:** ativam Correnteza 3. Duas unidades sustentam o grupo e uma causa magia; Seiva fica em 2/3 e não dá bônus.
- **Boto + Capeta do Vilarinho + Loira do Bonfim:** ativam Encanto 2, com dois Suportes e um Assassino. Os outros vínculos da pesquisa aparecem como diferenças de comportamento, não como mais um bônus automático.
- **Cumacanga + Perna Cabeluda + Corpo-Seco:** ativam Assombro 2, com uma Conjuradora e dois Atacantes. A marca conecta o dano mágico ao físico.

## 10. Raridade, distribuição e equilíbrio inicial

| Função | Quantidade |
| --- | ---: |
| Tank | 13 |
| Conjurador | 12 |
| Atacante | 7 |
| Assassino | 8 |
| Suporte | 14 |
| Porradeiro | 12 |

| Custo / raridade | Quantidade |
| --- | ---: |
| 1 | 9 |
| 2 | 15 |
| 3 | 17 |
| 4 | 11 |
| 5 — Lendária | 14 |

A abundância de Tanks e Suportes permite formar frentes e auras sem obrigar todo time a repetir as mesmas peças. Há menos Atacantes porque Porradeiros, Assassinos e Conjuradores também são fontes de dano; isso não dispensa conferir se os sete Atacantes ficam disputados demais na loja.

As equipes regionais têm **duas lendárias cada** e pelo menos uma delas exerce função ofensiva. Isso evita que uma região termine apenas com lendárias de defesa e apoio enquanto outra concentra duas fontes de dano de custo 5.

### Custo das formações completas

Valores para uma cópia de cada unidade, antes de estrelas, compras repetidas e atualização da loja:

| Região | Custo total | Principal contrapartida |
| --- | ---: | --- |
| Cerrado | 25 gold | Boa presença física e apenas um Suporte. |
| Caatinga | 26 gold | Várias ativações iniciais, sem patamar avançado; dano lendário concentrado no Boi. |
| Mata Atlântica | 22 gold | Muitas peças baratas permitem montar Seiva 6, mas o dano final depende de proteção e crescimento. |
| Litoral | 28 gold | Abertura mágica e Encanto 4, com dependência de lançamentos repetidos. |
| Pantanal | 27 gold | Mobilidade e explosão, com risco de sair do alcance das auras. |
| Amazônia | 31 gold | Mais peças caras e dano próprio elevado, sem chegar a seis integrantes de uma origem. |

Essa diferença é uma escolha inicial de identidade e acessibilidade, **não uma compensação de poder já comprovada**. Num modo de compra, a formação barata deixa mais recursos para evolução e busca de cópias. Numa campanha com inimigos gerados automaticamente, essa vantagem econômica não existe: será preciso ajustar a entrada das peças e as estrelas por região, usando o mesmo objetivo de dificuldade. Não se deve copiar uma progressão idêntica de estrelas e presumir equivalência entre esses elencos.

### O que precisa ser medido no protótipo

- Vitória entre as seis equipes em condições iguais de estrelas, orçamento de atributos e posicionamento alternado. Duas lendárias e nove unidades não garantem equilíbrio.
- Dano causado por papel: Tanks e Suportes devem continuar abaixo dos carregadores; Assassinos precisam mostrar pico, Atacantes crescimento e Porradeiros pressão constante.
- Tempo até primeiro e segundo lançamento; observar principalmente Fulgor, Vozes e Encanto em conjunto.
- Cura e escudos efetivos, especialmente Seiva + Vigília e as auras de Suporte.
- Tempo real sem poder agir; verificar a janela de imunidade entre controles fortes.
- Oportunidade de comprar peças de custos 1–3 antes de depender de lendárias. Não alterar chances de loja só porque o catálogo cresceu: primeiro medir distribuição por custo.
- Disputa por peças repetidas entre equipes. Compartilhar Boi Misterioso entre Cerrado e Caatinga é permitido e intencional; suas probabilidades e disponibilidade precisam respeitar o modelo de loja escolhido.
- Viabilidade dos patamares 8 e 9 contra composições mistas. O patamar máximo não deve vencer automaticamente; ele troca flexibilidade por especialização.

## 11. Conferência da proposta e implementação futura

### Conferência estrutural realizada

- **66 identidades únicas**, todas com custo, função, duas origens e conceito de habilidade.
- Os **45 nomes existentes** foram confrontados com o catálogo local; as 21 candidatas completam o conjunto pesquisado.
- **Nove origens**, todas com integrantes suficientes para o maior patamar.
- **Seis equipes de nove identidades distintas**, cada uma com **duas lendárias**.
- Todas as equipes principais contêm as **seis funções**, com pelo menos dois Tanks e uma lendária ofensiva.
- **47 unidades nas equipes principais + 19 alternativas = 66 unidades contempladas.**
- As **19 trocas individuais** preservam nove identidades, duas lendárias e presença das seis funções.
- **Nove composições máximas** verificadas: cada uma usa nove identidades, alcança o patamar indicado e possui ao menos um Tank, um Suporte e fonte de dano.
- Patamares ativos e mudanças das trocas foram calculados a partir das atribuições do catálogo deste documento.

Essa conferência valida a estrutura, não o balanceamento numérico. Não foram simulados combates desta proposta.

### Mudanças necessárias quando a proposta for implementada

O projeto atual admite uma origem por unidade nas regras de design e aplica bônus de sinergia de forma diferente desta proposta. A implementação precisará aceitar duas origens, separar função de combate das antigas classes, aplicar benefícios apenas aos integrantes elegíveis e fixar as contagens no começo da luta. Também precisará dos efeitos periódicos, limites de marcas, auras, seleção de vítimas e novas habilidades aqui descritos.

Será necessário cadastrar as 21 candidatas, ajustar as mudanças de função e raridade, substituir os elencos regionais e revisar a progressão de entrada por round. Descrições e bestiário devem mostrar os efeitos reais, as duas origens e o papel, sem apresentar as associações criativas como fatos históricos.

**Estado desta entrega:** proposta completa registrada para revisão e futura implementação; apenas documentação criada. A pesquisa narrativa e o documento anterior permanecem preservados.

