# Pequi — Ficha de design (Design Brief)

## Frase de silhueta
"Pequizeiro ancestral de tronco suberoso profundamente retorcido em arco de foice/berço ('C'), ostentando uma fenda incandescente de seiva no alto, um grande fruto rachado sobre o galho frontal e uma semente espinhosa arcana levitando no vão central, coroado por folhas trifolioladas e frutos globosos."

## Três formas-base
1. **Forma primária (massa dominante):** Arco orgânico assimétrico em "C" (foice/berço de vigília) formado pelo tronco tortuoso e suberoso que nasce de raízes nodosas no solo (`Z = 0`), curva-se para a esquerda (`-X`) e volta a projetar a copa superior e o galho-berço frontal para a direita (`+X`).
2. **Forma secundária (o que quebra a silhueta):** Esfera estrelada/espinhosa levitante no centro geométrico do arco (**Semente Espinhosa** arcana crivada de espinhos cônicos) combinada com o grande fruto de pequi rachado ao meio repousando sobre o galho-berço inferior direito.
3. **Forma terciária (detalhe de leitura):** Fenda vertical incandescente de seiva âmbar-dourada na curvatura interna superior do tronco ("olho de vigília"), cachos de frutos verdes globosos pendentes e tufos de folhas coriáceas trifolioladas de nervuras marcadas.

## Proporção
- **Nº de cabeças:** Equivalente a ~5,5 unidades do fruto aberto principal (~32 cm de diâmetro do fruto ritual aberto) ou ~7,0 vezes o diâmetro da Semente Espinhosa central (25 cm).
- **Altura em metros:** **1,75 m** de altura total (do solo `Z = 0.0` ao ápice da folhagem superior) e **1,42 m** de envergadura lateral, respeitando o limite de célula do tabuleiro definido para unidades de `Flora` (`height_limit <= 1.9 m`, `width <= 1.65 m`).
- **Relação com a unidade-âncora (`mae_dagua` e `comadre_fulozinha`):** Tem altura próxima à Mãe d'Água (1,82 m) e maior porte vertical que a Comadre Fulozinha (1,35 m), mas distingue-se radicalmente por sua silhueta botânica vazada em arco com núcleo flutuante e base enraizada (`is_stationary = true`).

## Paleta (com hex)
- **Cor dominante (Casca suberosa do Cerrado):** `#3B2B22` (marrom-cortiça queimado com fissuras profundas `#1E1510` e cristas acinzentadas de líquen `#5E574A`) — origem no texto: *"tronco tortuoso... casca grossa, suberosa (cortiçosa), áspera e profundamente fissurada"*.
- **Cor secundária (Folhagem coriácea e exocarpo dos frutos):** `#3E5A28` (verde-oliva cerradense nas folhas e frutos fechados, com variações `#567533` e manchas terrosas `#4A4326`) — origem: *"A casca guarda o verde das matas... folhas grandes coriáceas trifolioladas"*.
- **Cor de acento 1 (Polpa e óleo sagrado do fruto aberto):** `#F29F05` e `#FFC72C` (amarelo-ouro intenso e alaranjado amanteigado da polpa exposta e gotas de óleo) — origem: *"polpa amarela e reluzente (ouro do cerrado)... herdou a cor dos cabelos dourados de Uadi"*.
- **Cor de acento 2 (Endocarpo / Semente Espinhosa):** `#B87324` com espinhos `#E6A832` e base lenhosa `#5C3814` — origem: *"caroço repleto de espinhos pontiagudos... Semente Espinhosa"*.
- **Emissivo (Seiva viva e aura da Semente Espinhosa):** `#FFB833` (brilho âmbar-solar intenso na fenda superior do tronco, nos espinhos da semente levitante e nos filamentos de energia).

## Materiais
| Parte | Material | roughness | metallic | Observação |
|---|---|---|---|---|
| Tronco e raízes suberosas | `Pequi_Mat` | 0.85 | 0.0 | Casca cortiçosa fosca, seca e profundamente sulcada do Cerrado |
| Folhas coriáceas | `Pequi_Mat` | 0.55 | 0.0 | Superfície cerosa semi-fosca com nervuras saltadas |
| Casca dos frutos (Exocarpo) | `Pequi_Mat` | 0.65 | 0.0 | Verde-musgo granuloso com manchas pardas |
| Polpa aberta e gotas de óleo | `Pequi_Mat` | 0.35 | 0.0 | Brilho úmido, oleoso e amanteigado (`roughness` mínimo permitido) |
| Semente Espinhosa e Fenda de Seiva | `Pequi_Mat` | 0.45 | 0.1 | Núcleo lenhoso-arcano com emissão âmbar `#FFB833` |

## Anatomia e elementos
- **Raízes e Base (`BaseRoots`):** 5 raízes nodosas radiais cravadas em `Z = 0.0` que sustentam a árvore sem deslocamento de terreno (`is_stationary = true`).
- **Tronco Principal em Arco (`MainTrunk`):** Coluna retorcida formada por feixes de madeira espiralados que sobem pela esquerda e arqueiam sobre o centro, abrindo uma cavidade/fenda luminosa de seiva (`SapFissure`) na face interna superior.
- **Galho-Berço e Fruto Aberto (`CradleBranch` + `OpenFruit`):** Ramo grosso que avança pela direita à meia-altura (`Z ~ 0.65 m`), sustentando o grande pequi rachado em duas metades com polpa dourada carnosa, gotas pendentes de óleo e o topo do caroço interno visível.
- **Semente Espinhosa Levitante (`SpinySeed_Core`):** Endocarpo ovalado suspenso no centro do arco (`Z ~ 0.98 m`), coberto por dezenas de espinhos cônicos afiados e envolvido por duas fitas/anéis espirais de energia e folhinhas orbitais.
- **Ramos Superiores, Folhas Trifolioladas e Frutos Fechados (`CanopyBranches`, `Foliage`, `ClosedFruits`):** Dois cachos de frutos globosos fechados (par inferior esquerdo e trio superior direito) e grupos de folhas trifolioladas que coroam a silhueta.

## Transformações e estados
- **Idle:** A *Semente Espinhosa* levita no centro girando lentamente e oscilando na vertical; a fenda de seiva e o fruto aberto pulsam suavemente; os galhos e folhas balançam como sob a brisa quente do Cerrado.
- **Attack:** O arco do tronco recua levemente em tensão elástica, o galho-berço impulsiona e a *Semente Espinhosa* dispara à frente em golpe perfurante antes de retornar magneticamente ao centro do arco.
- **Stunned:** A *Semente Espinhosa* perde sustentação e cai sobre o fruto aberto; o tronco arqueado encolhe-se trêmulo para baixo e os ramos laterais arriam.
- **Channel:** O tronco se ergue abrindo o arco, o fruto aberto pulsa intensamente e a *Semente Espinhosa* gira acelerada subindo em espiral enquanto absorve a seiva dourada.
- **Death:** A energia da fenda e da semente se apaga; a *Semente Espinhosa* despenca no berço, as metades do fruto aberto se retraem e o tronco tortuoso míngua/cede sobre as próprias raízes em pose final estática.
- **Ability (*Semente Espinhosa*):** Compressão profunda das raízes e do arco seguida de abertura majestosa da copa: o fruto aberto libera o pulso curativo de óleo dourado (`ability_heal = 110`) e a *Semente Espinhosa* expande seus espinhos e é arremessada com explosão arcana.

## Movimento
- **Vocabulário:** Tensão lenhosa elástica (torção de fibras de madeira pesada), levitação giroscópica da semente central e pulsação orgânica do fruto aberto. Não há caminhada (`is_stationary = true`).
- **Ritmo:** Repouso lento e hipnótico contrastando com o disparo súbito e espinhoso no ataque e na habilidade (fonte: `art/lore/pequi.md` e `resources/units/pequi.tres`).

## Elementos secundários
- **Núcleo da Semente Espinhosa e anéis de órbita:** 3 bones dedicados (`seed_core`, `seed_orbit_l`, `seed_orbit_r`) permitindo levitação, rotação em 360° e arremesso independente do tronco.
- **Galho-berço e valvas do fruto aberto:** 4 bones (`branch_cradle_01`, `branch_cradle_02`, `fruit_valve_l`, `fruit_valve_r`) para abrir/fechar o fruto e pulsar a polpa dourada.
- **Ramos da copa e cachos de frutos fechados:** Cadeias secundárias para balanço de folhagem e frutos pendentes (total previsto da armature: **30 a 34 bones**, dentro da meta de `25–45`).

## Decisões autorais (precisam de aprovação)
1. **Fechamento traseiro do tronco suberoso e da fenda de seiva (ausente na vista frontal da splash art):**
   - Propomos esculpir o dorso (`+Y` traseiro) com placas de casca cortiçosa contínua e sulcos espirais que sobem das raízes até a copa, deixando uma fresta secundária estreita de seiva âmbar nas costas para manter a leitura luminosa também quando visto por trás.
2. **Semente Espinhosa levitante controlada por bone desconectado (filho de `spine_02`):**
   - Para viabilizar as animações de `Attack` e `Ability` sem criar partículas externas fora do `.glb`, a *Semente Espinhosa* central e seus filamentos orbitais fazem parte da malha única `Pequi`, mas são pesados em bones próprios (`seed_core`, `seed_orbit_l/r`), permitindo que ela flutue, gire e dê o bote à frente mantendo o contrato de 1 único objeto de malha e 1 material.
3. **Base enraizada direta sem pedestal de pedra acoplado:**
   - Embora a splash art mostre rochas do Cerrado no cenário ao redor, propomos terminar a malha exatamente nas 5 raízes nodosas apoiadas em `Z = 0.0` (sem chão de pedra preso ao personagem), garantindo integração limpa com qualquer hexágono do tabuleiro da Godot.

## Descartado
- **Ent humanoide com pernas, braços e rosto esculpido (boca/nariz):** Descartado por violar a natureza estacionária (`is_stationary = true`) da unidade `Flora` e por destoar da splash art oficial (`Assets/Units/SplashArts/pequi.png`), onde o mistério vem da forma botânica retorcida e da fenda de seiva.
- **Árvore genérica simétrica de tronco reto (`CommonTree_2`):** Descartada; o pequizeiro do Cerrado exige tronco tortuoso assimétrico e destaque em escala para o fruto aberto e a semente espinhosa.

