# Ficha de Unidade — Mãe-D'Água (`mae_dagua`)

**Fonte de dados:** `resources/units/mae_dagua.tres`  
**Concept Art de referência:** `art/concepts/mae_dagua/mae_dagua_concept.png` (`Assets/Units_teste/Mãe_dafua.png`)  
**Splash / Ícone atual:** `art/concepts/mae_dagua/mae_dagua_splash_xilo.jpg` (`Assets/Units/SplashArts/mae_agua.jpg`)

---

## 1. Atributos de Gameplay

| Propriedade | Valor |
|---|---|
| **ID (`unit_id`)** | `mae_dagua` |
| **Nome (`unit_name`)** | Mãe-D'Água |
| **Tier / Custo** | Tier 5 / 5 de ouro |
| **Função (`combat_role`)** | Suporte (Backline, alcance corpo-a-corpo 1 casa, `prefers_backline = true`) |
| **Origens / Sinergias** | `Correnteza`, `Encanto` |
| **Vida Máxima** | 1500.0 (Regen: 15.0/s) |
| **Dano / Vel. de Ataque** | 65.0 / 1.00 |
| **Armadura / Res. Mágica** | 45.0 / 75.0 |
| **Mana (Inicial / Por seg.)** | 50.0 / 10.0 |
| **Habilidade Ativa** | **Bênção das Águas** — Cura 350.0 e concede 240.0 de escudo para até 4 aliados (alcance 10.0) enquanto sua canção ecoa pelo campo. |
| **Passiva de Aura** | Regeneração (`regen`, alcance 1 casa, potência 2% HP/s). |

---

## 2. Diretrizes Visuais e de Escala para Modelagem 3D

- **Papel Visual no Tabuleiro:** Unidade lendária de Tier 5 (Suporte Régio). Deve ter silhueta imponente e imediatamente reconhecível na câmera isométrica do tabuleiro, destacando-se pelo **cocar em leque**, **cabelos negros volumosos abertos nas laterais** e **longa cauda de peixe arqueada em S**.
- **Proporção:** ~7 cabeças de comprimento total desenrolado; em postura de repouso (apoiada na curva da cauda com a nadadeira caudal erguida ao lado do corpo), altura vertical de aproximadamente **1,85 m a 1,95 m** (incluindo cocar).
- **Assinatura de Animação:**
  - `Idle`: Ondulação contínua em "S" da cauda e nadadeiras, respiração serena, braços semiabertos com energia aquática sutil.
  - `Attack`: Golpe fluido com chicoteio de água/braço ou varredura de cauda curta, retornando à pose régia.
  - `Stunned`: Tronco curvado, cabeça baixa, cauda trêmula perdendo sustentação momentânea.
  - `Channel`: Mãos erguidas próximas ao peito/boca, peito expandido entoando o canto hipnótico, cauda ondulando em ritmo hipnótico.
  - `Death`: Perda de força no torso, giro suave e colapso sobre a lateral da cauda no chão.
  - `Ability` (*Bênção das Águas*): Elevação majestosa sobre a base da cauda, braços abertos em arco amplo invocando a maré curativa e abertura total do leque caudal.

