# Pequi (`pequi`) — Relatório de modelagem

## 1. Leitura da descrição (o que o texto diz, em 10 linhas)

O **Pequi** (*Caryocar brasiliense* Cambess.), cujo nome provém do tupi ***pyqui*** (*py* = pele/casca + *qui* = espinho, isto é, **"pele espinhosa"**), é a árvore-símbolo do **Cerrado** brasileiro e uma entidade de `Flora` com origens `Seiva` e `Vigília`.
Na tradição mítica indígena (lenda de **Tainá-racan, Maluá e do menino Uadi**, além da cosmologia Karib dos povos **Kuikuro e Kalapalo** do Alto Xingu) e nas narrativas sertanejas/quilombolas do Brasil Central, o pequizeiro encarna a dualidade entre **dádiva nutritiva e proteção espinhosa**.
Sua casca verde-musgo guarda a polpa carnosa amarelo-ouro ("ouro do Cerrado", herdada dos cabelos solares de Uadi) que nutre e cura quem respeita a árvore, mas esconde em seu âmago um **endocarpo lenhoso crivado de centenas de espinhos agudos** que perfuram a boca de quem o morde com ganância.
Visualmente, conforme o texto canônico (`art/lore/pequi.md`) e a referência (`art/concepts/pequi/pequi_splash.png`), apresenta-se como um **pequizeiro ancestral de tronco suberoso profundamente retorcido em arco ("C")**, enraizado firmemente no chão (`is_stationary = true`).
No alto da curvatura interna do tronco abre-se uma **fenda vertical incandescente de seiva âmbar-dourada** ("olho de vigília").
À frente e à direita, um **galho robusto em forma de berço/garra** sustenta um **grande fruto de pequi rachado ao meio**, expondo a polpa amarelo-ouro brilhante que escorre em gotas densas de óleo sagrado sobre o topo escuro do caroço interno.
No espaço central emoldurado pelo arco do tronco levita a **Semente Espinhosa** arcana — um grande caroço dourado-bronze eriçado de espinhos cônicos e envolvido por anéis de energia solar.
A copa assimétrica completa a silhueta com **folhas coriáceas compostas trifolioladas** de nervuras marcadas e **cachos de frutos verdes globosos fechados** pendentes nos ramos.
Em combate (`resources/units/pequi.tres`), atua como **Suporte estacionário de Tier 1** (`ability_heal = 110.0`, aura defensiva), disparando a *Semente Espinhosa* que explode no alvo enquanto revigora os aliados.

---

## 2. Canônico / derivado / autoral (tabela de decisões)

| Elemento / Decisão | Classificação | Origem / Justificativa |
|---|---|---|
| Tronco tortuoso em arco ("C") com casca grossa suberosa e raízes no solo (`Z = 0`) | **Canônico** | `art/lore/pequi.md` (seções 2 e 8), botânica do *Caryocar brasiliense* (`F01`) e `pequi_splash.png`. |
| Fenda superior incandescente de seiva âmbar-dourada (`#FFB833`) no arco | **Canônico** | `art/lore/pequi.md` (seção 2) e origem `Seiva` / `Vigília` (`resources/units/pequi.tres`). |
| Galho-berço frontal direito sustentando um grande fruto aberto com polpa amarelo-ouro (`#F29F05`) e gotas de óleo (`#FFC72C`) | **Canônico** | `art/lore/pequi.md` (seções 2 e 8), `pequi_splash.png` e cura da habilidade (`ability_heal = 110.0`). |
| **Semente Espinhosa** levitando no centro do arco, coberta de espinhos cônicos e órbitas douradas | **Canônico** | `resources/units/pequi.tres` (*"Semente Espinhosa: arremessa sementes repletas de espinhos arcanos"*), `art/lore/pequi.md` e `pequi_splash.png`. |
| Folhas coriáceas compostas **trifolioladas** e cachos de frutos verdes fechados (2 à esquerda, 3 à direita) | **Canônico** | Morfologia botânica do *Caryocar brasiliense* (`F01`, `F02`), `art/lore/pequi.md` e `pequi_splash.png`. |
| Contraste de `roughness` entre casca cortiçosa seca (`0.85`) e polpa/óleo amanteigado (`0.35`) | **Derivado** | Dedução material direta da descrição de casca suberosa de Cerrado vs. polpa oleosa reluzente (`DESIGN_BRIEF.md`). |
| Fechamento dorsal do tronco com feixes espirais de casca e **fresta secundária traseira de seiva** | **Autoral (Proposta 1)** | A referência visual mostra apenas a vista frontal; a fresta dorsal mantém leitura viva em 360° e na câmera do tabuleiro. |
| Semente Espinhosa e fitas orbitais integradas à malha única, pesadas em bones próprios desconectados (`seed_core`, `seed_orbit_l/r`) | **Autoral (Proposta 2)** | Permite levitação, giro em 360° e disparo elástico em `Attack`/`Ability` respeitando o limite de 1 único objeto de malha e 1 material no `.glb`. |
| Base terminada nas 5 raízes nodosas apoiadas em `Z = 0.0` sem pedestal de rocha acoplado | **Autoral (Proposta 3)** | Garante apoio limpo e sem colisão visual em qualquer célula hexagonal do tabuleiro da Godot. |
| Ent humanoide bípede com pernas/rosto ou árvore europeia reta (`CommonTree_2`) | **Descartado** | Viola `is_stationary = true` e descaracteriza a anatomia tortuosa do pequizeiro do Cerrado. |

---

## 3. Pesquisa complementar e fontes (link + data)

A pesquisa complementar sobre o **Pequi** (*Caryocar brasiliense*) consolidou três eixos culturais e botânicos fundamentais para o projeto:
1. **Etimologia Tupi e Botânica do Cerrado:** O vocábulo *pequi* deriva do tupi *py* (pele, casca) + *qui* (espinho), significando literalmente **"pele espinhosa"**, em referência ao endocarpo (putâmen) revestido por milhares de microespinhos rijos sob a polpa amarela rica em óleo. O pequizeiro possui tronco tortuoso de casca grossa e suberosa (adaptada à pirofisionomia do Cerrado) e folhas compostas trifolioladas grandes e coriáceas.
2. **Cosmologia Indígena (Mito de Uadi e Povos do Alto Xingu):** Na narrativa mítica de **Tainá-racan, Maluá e seu filho Uadi (Arco-Íris)**, a metamorfose do menino deu origem ao fruto: o verde da mata na casca, o ouro solar dos cabelos de Uadi na polpa nutritiva e os espinhos da dor e proteção materna no caroço. Entre os povos Karib do Alto Xingu (**Kuikuro** e **Kalapalo**), o pequi possui mitos próprios de origem ancestral, pomares manejados há séculos e ligação ritual com os troncos sagrados do *Kuarup*.
3. **Tradição Sertaneja e Quilombola:** No folclore do Brasil Central, o pequizeiro brotou do sacrifício de uma mulher fugitiva acolhida pelas raízes de uma árvore seca do sertão, tornando-se símbolo de fartura, cura e resistência — contanto que quem o consuma tenha respeito e jamais morda seu núcleo espinhoso.
- **Erros comuns evitados:** (1) modelar um "homem-árvore" bípede genérico de fantasia medieval; (2) usar copa simétrica de carvalho/pinheiro sem tronco tortuoso; (3) representar as folhas como simples em vez de trifolioladas; (4) omitir o contraste entre casca verde, polpa amarelo-ouro e caroço espinhoso.

### Fontes consultadas:
1. **Embrapa (Empresa Brasileira de Pesquisa Agropecuária — Embrapa Cerrados):** *Pequi (Caryocar brasiliense Cambess.): botânica, etimologia tupi ("pele espinhosa") e ecologia no Cerrado*. Disponível em: https://www.embrapa.br/cerrados — Acesso em: 10/11/2026.
2. **Rede Cerratinga / Instituto Sociedade, População e Natureza (ISPN):** *Espécies do Cerrado — Pequi (Caryocar brasiliense): usos tradicionais, óleo, polpa e sociobiodiversidade*. Disponível em: https://www.cerratinga.org.br/especies/pequi/ e https://ispn.org.br/ — Acesso em: 10/11/2026.
3. **Instituto Socioambiental (ISA) — Povos Indígenas no Brasil:** *Povos do Alto Xingu (Kuikuro e Kalapalo), cosmologia de origem do pequi e manejo tradicional dos pequizais*. Disponível em: https://pib.socioambiental.org/ — Acesso em: 10/11/2026.
4. **Portal Entretextos / Literatura e Folclore do Brasil Central:** *A Lenda do Pequi — O mito indígena de Tainá-racan, Maluá e Uadi, e a tradição popular do Cerrado*. Disponível em: https://www.portalentretextos.com.br/ — Acesso em: 10/11/2026.

---

## 4. Referências audiovisuais (timestamps + o que foi visto)

Os links de referência listados em `docs/Links_videos_modelagem.txt` (copiados em `art/videos/pequi/links.txt`) foram verificados a partir das transcrições `.vtt` e dos 18 quadros extraídos via FFmpeg no repositório (`art/videos/mae_dagua/frames/`):
1. **Vídeo 1 — `qSR-qK2vRQY` (*Base Meshes - Free Asset Bundle*, Joey Carlino, 03:33):**
   - `00:37` a `01:15`: Apresenta organização de malhas-base limpas em quads e proporções estilizadas.
2. **Vídeo 2 — `O6HQhs-gk50` (*Character modeling for beginners - Blender*, Joey Carlino, 48:02):**
   - `08:34` a `34:18`: Blocagem de formas primárias e secundárias por extrusão, curvas chanfradas e modificadores *Solidify* / *Subdivision* antes da unificação.
3. **Vídeo 3 — `m-Obo_nC3SM` (*Rigging for beginners - Blender tutorial*, Joey Carlino, 59:26):**
   - `10:36` a `42:27`: Estruturação de *Armature* hierárquica limpa a partir do `root` em `(0,0,0)` e cadeias secundárias para apêndices flexíveis.
- **Declaração de limitação:** Os vídeos fornecidos são tutoriais técnicos gerais de modelagem e rigging no Blender e não exibem uma criatura/árvore de Pequi animada. Portanto, o vocabulário de movimento (levitação giroscópica da *Semente Espinhosa*, pulsação do fruto aberto e tensão elástica do tronco arqueado em *Attack* e *Ability*, mantendo `is_stationary = true`) foi derivado diretamente de `art/lore/pequi.md` e `resources/units/pequi.tres`.

---

## 5. Especificação técnica (Status atual: Fase 4 — Checkpoint de Blockout)

- **Status atual:** **Fase 1 a 4 Concluídas** (Lore redigido em `art/lore/pequi.md`, Ficha em `docs/units/pequi.md`, `models/pequi/DESIGN_BRIEF.md`, Blockout `models/pequi/pequi_blockout.blend` e Prancha `models/pequi/renders/interpretacao.png`).
- **Altura e Envergadura do Blockout:** `1,75 m` de altura (`Z = 0.0` a `1.75 m`), `1,42 m` de largura, base enraizada em `Z = 0.0`.
- **Próximas etapas após aprovação:** Etapa A/B (Retopo unificado 6.000–9.000 triângulos e UV sem sobreposição), Etapa C (Atlas PBR 1024×1024 Base Color + Normal Map), Etapa D (Rig 25–45 bones com até 4 influências/vértice), Fase 9 (6 clipes NLA: `Idle`, `Attack`, `Stunned`, `Channel`, `Death`, `Ability`) e Fase 10–11 (Export `.glb` e validação na Godot 4.x).

