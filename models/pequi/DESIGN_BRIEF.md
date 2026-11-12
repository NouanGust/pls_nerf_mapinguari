# DESIGN BRIEF — PEQUI (Folchess)

## 1. Identidade & Papel de Jogo
- **Nome:** Pequi (*Caryocar brasiliense*)
- **ID:** `pequi`
- **Origem / Bioma:** Cerrado | Seiva & Vigília
- **Papel:** Suporte / Conjurador Vegetal Estacionário (`is_stationary = true`)
- **Ataque / Alcance:** Disparo à distância (arremesso de semente pontiaguda/espinhosa) e aura de suporte defensiva aos aliados no entorno.

---

## 2. Tradução Visual & Silhueta do Modelo
A modelagem traduz a arte conceitual oficial do jogo (`pequi.png`):
1. **Tronco Centenário do Cerrado:**
   - Tronco grosso, nodoso e retorcido, expressando a resistência à seca e ao fogo.
   - Base com raízes espraiadas e firmes apoiadas no solo do tabuleiro.
   - Olho/fenda sentinela vegetal em brasa âmbar no centro do tronco, dando direção clara de visada.
2. **Copa de Galhos Arqueados e Folhagem:**
   - Braços/galhos que se arqueiam em garras protegendo o centro.
   - Folhagem estilizada em tufos ovais verdes com bordas levemente amareladas.
3. **O Fruto Guardião (Núcleo Místico):**
   - Um fruto de pequi gigante aberto ao meio (casca verde-oliva rugosa, polpa amarela carnosa).
   - O caroço sagrado (endocarpo) com espinhos afiados flutuando/alojado no cálice central, cercado por brilho dourado de seiva mágica.

---

## 3. Especificações Técnicas
- **Geometria:** Malha única `Pequi` com ~7.000 a 10.000 triângulos (respeitando o teto de 15.000).
- **Texturização PBR:** 1 Atlas 1024x1024 (Base Color, Roughness, Normal, Emissive para a seiva e polpa).
- **Armature & Rig:** 14 ossos essenciais (`Root`, `Trunk_01`, `Trunk_02`, `Eye_Core`, `Branch_L_01`, `Branch_L_02`, `Branch_R_01`, `Branch_R_02`, `Fruit_Core`, `Spike_Seed`, `Root_01`, `Root_02`, `Root_03`).
- **Animações:** 6 NLA Actions integradas (`Idle`, `Attack`, `Ability`, `Channel`, `Stunned`, `Death`).

