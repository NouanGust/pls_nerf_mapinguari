# Ficha de Unidade — Pequi (`pequi`)

**Fonte de dados:** `resources/units/pequi.tres` e `docs/MODELOS_FAUNA_FLORA.md`  
**Descrição canônica da lenda:** `art/lore/pequi.md`  
**Imagens de apoio:** `art/concepts/pequi/pequi_splash.png` (`Assets/Units/SplashArts/pequi.png`) e `art/concepts/pequi/pequi_ref.jpg` (`Assets/Units/SplashArts/pequi.jpg`)

---

## 1. Atributos de Gameplay

| Propriedade | Valor |
|---|---|
| **ID (`unit_id`)** | `pequi` |
| **Nome (`unit_name`)** | Pequi |
| **Tier / Custo** | Tier 1 / 1 de ouro |
| **Função (`combat_role`)** | Suporte (`prefers_backline = true`, `is_stationary = true`) |
| **Movimentação** | Estacionária (`movement_speed = 0.0`, enraizada na casa do tabuleiro) |
| **Origens / Sinergias** | `Seiva`, `Vigília` |
| **Afinidade / Bioma** | `Flora` / `Cerrado` |
| **Vida Máxima** | 460.0 |
| **Dano / Vel. de Ataque** | 32.0 / 0.85 |
| **Armadura / Res. Mágica** | 15.0 / 20.0 |
| **Mana (Máxima / Por seg.)** | 75.0 / 3.0 |
| **Habilidade Ativa** | **Semente Espinhosa** — *"Fruto emblemático do Cerrado; arremessa sementes repletas de espinhos arcanos que explodem no alvo."* (`ability_heal = 110.0`) |
| **Passiva de Aura** | Aura de suporte/defesa (`passive_aura_effect = "defense"`, `passive_aura_power = 12.0`, aura de Flora no tabuleiro). |

---

## 2. Diretrizes Visuais e de Escala para Modelagem 3D

- **Papel Visual no Tabuleiro:** Unidade estacionária de Flora do Cerrado (Tier 1). Substitui o placeholder genérico (`CommonTree_2.obj`) por um modelo autoral riggado e animado que traduz fielmente a identidade do pequizeiro místico: **tronco tortuoso arqueado em "C" com fenda de seiva luminosa**, **galho-berço frontal com grande fruto de pequi aberto (polpa amarelo-ouro)** e a **Semente Espinhosa arcana levitando no vão central do arco**, coroado por **folhas coriáceas trifolioladas e frutos verdes pendentes**.
- **Proporção e Escala:** Altura total de **1,75 m** e largura de copa/base contida dentro do limite de célula hexagonal do tabuleiro (~1,45 m de diâmetro máximo), mantendo leitura clara a 20 metros de distância na câmera isométrica.
- **Assinatura de Animação (6 estados obrigatórios sem Root Motion):**
  - `Idle` (Loop): Pulsação suave da fenda de seiva, levitação giratória e oscilação vertical da *Semente Espinhosa* no centro do arco, respiração lenta dos galhos e balanço das folhas/frutos pendentes.
  - `Attack`: O tronco arqueado se retesa para trás (antecipação), o galho-berço se abre e a *Semente Espinhosa* central avança/dispara em chicote energético para a frente (+Y/-Y conforme orientação), retornando ao centro em recarga imediata.
  - `Stunned` (Loop): A semente levitante cai pesadamente sobre o fruto aberto perdendo o brilho, o tronco se encolhe trêmulo e os ramos pendem atordoados.
  - `Channel` (Loop): O arco do tronco se expande, o fruto aberto pulsa liberando vapores/gotas douradas e a *Semente Espinhosa* gira rapidamente subindo em espiral no centro.
  - `Death`: A semente central se apaga e despenca no berço, o fruto aberto se fecha parcialmente e o tronco tortuoso cede e míngua sobre as próprias raízes em pose estática.
  - `Ability` (*Semente Espinhosa*): Grande compressão das raízes e do arco do tronco seguida de expansão explosiva: os galhos se abrem em coroa, o fruto rachado libera a onda nutritiva dourada (`ability_heal`) e a *Semente Espinhosa* cresce e é arremessada com giro arcano intenso antes de se reconstituir no centro.

