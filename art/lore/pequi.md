# Lore e Especificação de Design — Pequi (Caryocar brasiliense)

> **Unidade:** Pequi  
> **Identificador interno:** `pequi`  
> **Origem / Bioma:** Cerrado | Seiva & Vigília  
> **Classe / Papel:** Suporte / Conjurador Vegetal Estacionário (`is_stationary = true`)  
> **Tier / Custo:** 1 Ouro  

---

## 1. Origem Folclórica e Narrativa

No Cerrado brasileiro, o Pequizeiro é a árvore-mãe da savana: seus troncos são densamente retorcidos pelo fogo e pela seca, com casca grossa e suberosa (cortiça protetora), folhas coriáceas e raízes profundas que buscam água no lençol freático ancestral. 

Em *Folchess*, o **Pequi** não é uma simples árvore cenográfica inerte: é uma **entidade vegetal viva e sentinela**, um guardião milenar que protege a fauna e os aliados ao seu redor com uma aura de vigor da seiva dourada. Ao ser provocado ou canalizar poder, seus galhos retorcidos abrem cápsulas de frutos carnosos revelando a polpa amarelo-âmbar incandescente e arremessando o temido endocarpo repleto de milhares de microespinhos arcanos que explodem nos invasores.

---

## 2. Tradução Visual & Silhueta

Baseado na arte canônica do projeto (`Assets/Units/SplashArts/pequi.png`):

1. **Estrutura / Tronco (Base):**
   - Tronco grosso, retorcido e nodoso típico do Cerrado (*tortuoso*), emergindo do solo com raízes expostas e garras de madeira que ancoram a unidade firmemente no hexágono.
   - Textura de casca fissurada, seca e profunda, com fendas orgânicas onde pulsa uma bioluminescência âmbar/dourada (a Seiva mágica).
2. **Copa e Galhos:**
   - Galhos arqueados em garras que emolduram o centro da criatura.
   - Folhas largas, ovaladas e coriáceas verde-oliva com brotos e musgo seco.
3. **O Fruto Guardião (Núcleo Místico):**
   - No centro dos galhos principais, situa-se um grande fruto de pequi aberto em drupa, exibindo a polpa carnosa amarelo-dourada reluzente.
   - Flutuando ou alojado no centro está o caroço lendário — uma semente esférica/ovóide eriçada de espinhos afiados, cercada por partículas de pólen dourado.
4. **Olho/Foco Sentinela:**
   - O oco do tronco ou o miolo da ramificação forma uma fenda expressiva em brasa mística (olho sentinela vegetal), garantindo legibilidade imediata de direção/frente da unidade no tabuleiro.

---

## 3. Especificações Técnicas de Modelagem

- **Orçamento de Triângulos:** 6.000 a 10.000 tris (teto máximo de 15.000 tris).
- **Material & Shading:** 1 material PBR Atlas único (1024x1024 Base Color, Roughness, Normal, Emissive para a seiva e polpa).
- **Armature & Rig:** 12 a 16 ossos essenciais:
  - `Root` (base no solo)
  - `Trunk_01`, `Trunk_02`, `Trunk_Head` (coluna da árvore para balanço de respiração e flexão)
  - `Branch_L_01`, `Branch_L_02`, `Branch_R_01`, `Branch_R_02` (galhos articulados que agitam nos ataques)
  - `Fruit_Core`, `Spike_Seed` (osso do fruto/semente para estalo de ataque e pulso de cura)
  - `Root_Claw_01`, `Root_Claw_02`, `Root_Claw_03` (raízes de suporte no solo)
- **6 Animações Canônicas:**
  - `Idle`: Pulso rítmico da seiva, tronco respirando, galhos e folhas oscilando com o vento do Cerrado.
  - `Attack`: Tronco recua como uma catapulta orgânica e estala para frente, arremessando a semente de espinhos.
  - `Ability`: Os galhos se abrem para o céu, o caroço brilha intensamente e libera uma explosão de seiva curativa e espinhos radiantes.
  - `Channel`: Vibração contínua dos galhos e brilho concentrado no núcleo do fruto.
  - `Stunned`: Tronco arqueia para trás, galhos murcham e o brilho da seiva pisca enfraquecido.
  - `Death`: A casca se fende, os galhos desabam sobre o solo e a semente central se apaga.

