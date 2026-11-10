# Mãe-D'Água (`mae_dagua`) — Relatório de modelagem

## 1. Resumo da lenda (10–20 linhas)

A **Mãe d'Água** (ou **Iara** / **Uiara**, do tupi *y* = água + *îara* = senhora, "Senhora das Águas") é uma das entidades mais emblemáticas do folclore brasileiro, com matriz principal na **Bacia Amazônica (Norte)** e variantes ribeirinhas no **Rio São Francisco (Nordeste/Sudeste)**, **Centro-Oeste** e **Sul**.
Segundo **Luís da Câmara Cascudo**, sua configuração atual resulta de uma hibridização secular: sobrepôs-se aos antigos mitos tupis do monstruoso *Ipupiara* (homem-marinho devorador) e da *Boiúna* (Cobra-Grande) a tradição ibérica das **sereias** e **mouras encantadas**, além de sincretismos com divindades aquáticas africanas (**Oxum** e **Iemanjá**).
Na narrativa oral amazônica consolidada, Iara era uma valente guerreira indígena, filha de um pajé, que matou os irmãos em legítima defesa quando estes tentaram assassiná-la por inveja; lançada pelo pai no encontro dos rios Negro e Solimões, foi salva pelos peixes sob a lua cheia e transformada em metade mulher, metade peixe.
Sua aparência tradicional na vertente amazônica combina **pele morena acobreada**, **longos cabelos negros ondulados** enfeitados com flores ou penas e uma **cauda ictiomórfica de escamas iridescentes** (verdes, azuis e douradas, como o pirarucu ou o tucunaré).
Habitando remansos, igarapés e cachoeiras, costuma emergir ao entardecer para pentear os cabelos e entoar um **canto hipnótico** de beleza irresistível, capaz de enfeitiçar pescadores e viajantes e atraí-los para o fundo das águas.
Aqueles que sobrevivem ao seu chamado permanecem em estado de torpor ou desvario ("assombrados de Iara"), exigindo rituais de pajelança para recobrar o espírito.
Entre os **elementos simbólicos** essenciais estão a água corrente bioluminescente, o cocar ritual indígena, colares de contas/sementes e a flora aquática (vitória-régia).
**Erros comuns evitados neste projeto:** (1) retratá-la como sereia europeia loura/marinha, preservando os traços indígenas e adornos amazônicos do concept art; (2) tratá-la como monstro bestial genérico, mantendo sua postura régia, solene e hipnótica; e (3) adicionar armas (tridentes) ou pernas humanas.

---

## 2. Fontes (link + data de acesso)

1. **Fundação Joaquim Nabuco (Fundaj) — Pesquisa Escolar:** *Iara / Mãe-d'Água*. Disponível em: https://pesquisaescolar.fundaj.gov.br/pt-br/artigo/iara/ — Acesso em: 07/11/2026.
2. **MultiRio (Secretaria Municipal de Educação do Rio de Janeiro):** *Série Juro que Vi — Iara e o Folclore Brasileiro*. Disponível em: https://www.multirio.rj.gov.br/ — Acesso em: 07/11/2026.
3. **CASCUDO, Luís da Câmara.** *Dicionário do Folclore Brasileiro* (verbetes *Iara*, *Mãe-d'Água* e *Ipupiara*) / Síntese documental em *Portal Amazônia* e *Wikipédia*. Disponível em: https://portalamazonia.com/amazonia/lenda-da-iara e https://pt.wikipedia.org/wiki/Iara_(folclore) — Acesso em: 07/11/2026.
4. **IEPHA-MG — Instituto Estadual do Patrimônio Histórico e Artístico de Minas Gerais:** *Inventário Cultural do Rio São Francisco* (entidades fluviais e Mãe d'Água). Disponível em: https://www.iepha.mg.gov.br/images/com_arismartbook/download/8/Inventario%20Cultural%20do%20Sao%20Francisco.pdf — Acesso em: 07/11/2026.

---

## 3. Referências audiovisuais analisadas (timestamps + o que foi visto)

Os três links listados em `docs/Links_videos_modelagem.txt` (copiados para `art/videos/mae_dagua/links.txt`) foram processados via `yt-dlp` (extração de legendas `.vtt` e metadados) e **Blender 4.5 Video Sequence Editor / FFmpeg** (extração de 18 quadros em `art/videos/mae_dagua/frames/`):

1. **Vídeo 1 — `qSR-qK2vRQY` (*Base Meshes - Free Asset Bundle*, Joey Carlino, 03:33):**
   - `00:37` (`qSR-qK2vRQY_f01_00m37s.jpg`): Apresenta as malhas-base CC0 do Blender Studio (`human-base-meshes-bundle-v1.4.1.zip`, presente em `docs/`), destacando cabeças, mãos, pés e crânios planares/estilizados.
   - `01:15` (`qSR-qK2vRQY_f02_01m15s.jpg`): Demonstra o modelo `Body Female - Stylized` e `Body Female - Primitive (Stylized)` com *face sets* e topologia limpa em quads para blocagem e escultura.
2. **Vídeo 2 — `O6HQhs-gk50` (*Character modeling for beginners - Blender*, Joey Carlino, 48:02):**
   - `08:34` (`O6HQhs-gk50_f01_08m34s.jpg`): Demonstra blocagem de proporções humanas por subdivisão e extrusão com modificador *Mirror*.
   - `17:09` a `34:18` (`O6HQhs-gk50_f02_17m09s.jpg` a `f04_34m18s.jpg`): Construção de volumes primários da cabeça, olhos e focinho com *Solidify* e *Subdivision*.
   - `42:53` a `51:27` (`O6HQhs-gk50_f05_42m53s.jpg` a `f06_51m27s.jpg`): Blocagem de mãos/dedos com modificador *Skin* e unificação final de objetos com aplicação de modificadores.
3. **Vídeo 3 — `m-Obo_nC3SM` (*Rigging for beginners - Blender tutorial*, Joey Carlino, 59:26):**
   - `10:36` a `21:13` (`m-Obo_nC3SM_f01_10m36s.jpg` a `f02_21m13s.jpg`): Construção de hierarquia limpa de *Armature* (coluna, clavículas, braços, dedos) e associação com *Automatic Weights*.
   - `31:50` a `42:27` (`m-Obo_nC3SM_f03_31m50s.jpg` a `f04_42m27s.jpg`): Configuração de cadeias secundárias, IK, orientação de *Bone Roll* e *Weight Painting* manual.
   - `53:03` a `63:40` (`m-Obo_nC3SM_f05_53m03s.jpg` a `f06_63m40s.jpg`): Uso de *Masking* e *Bendy Bones* para curvas suaves e teste de deformação em poses extremas.

- **O que os vídeos confirmam / contradizem:** Confirmam diretamente o pipeline técnico do projeto — uso do bundle local `docs/human-base-meshes-bundle-v1.4.1.zip` (`Body Female - Primitive (Stylized)`) como ponto de partida anatômico para o busto/cabeça/mãos, modelagem por blocos limpos e rig com cadeias dedicadas para apêndices secundários (cauda, nadadeiras e cabelo). Não há contradição com o concept art.
- **Declaração de limitação e vocabulário de movimento:** Os três vídeos fornecidos no repositório são tutoriais técnicos de modelagem e rigging no Blender, não contendo animação da criatura folclórica Mãe d'Água. Portanto, o vocabulário de movimento (`Idle` com ondulação contínua em "S" da cauda e nadadeiras em leque, `Channel` e `Ability` com elevação sobre a base da cauda e abertura dos braços invocando a *Bênção das Águas*) foi derivado da leitura do concept art (`art/concepts/mae_dagua/mae_dagua_concept.png`), da ficha de gameplay (`resources/units/mae_dagua.tres`) e da tradição folclórica.

---

## 4. Decisões de arte (o que veio do concept, o que foi escolha minha)

### 4.1 Checklist de leitura do concept (`art/concepts/mae_dagua/mae_dagua_concept.png`)
- **Silhueta dominante em uma frase:** Sereia indígena amazônica de porte régio, coroada por cocar em leque amplo e cabeleira negra esvoaçante, sustentada sobre uma longa cauda de peixe arqueada em "S" com grande nadadeira caudal erguida à sua direita.
- **Formas-base (3 formas geométricas para blockout):**
  1. **Coroa / Leque trapezoidal** (cocar + massa ampla dos cabelos negros na metade superior);
  2. **Ampulheta / Cone invertido** (busto humanoide feminino esguio com braços abertos em "A" a ~28°);
  3. **Cilindro cônico curvo em "S"** (cauda muscular que desce até o solo em `Z = 0` e sobe lateralmente até a altura do ombro, terminando em leque duplo).
- **Pontos de exagero (leitura a 20 m no tabuleiro):**
  - Penacho central laranja-dourado e abertura radial do cocar;
  - Volume lateral amplo das ondas de cabelo negro contrastando com a cintura fina;
  - Curva em "S" da cauda com a grande nadadeira caudal bicolor (âmbar/turquesa) elevada ao lado do corpo;
  - Brilho emissivo ciano (`#43F0D3`) nos antebraços/mãos.
- **Paleta extraída do concept (Hex):**
  - Pele indígena acobreada: `#9C5A38` (sombra `#6E3B22`, luz `#B8734B`)
  - Escamas azul-petróleo / turquesa: `#1F6E75` a `#16324F`
  - Dourado / Âmbar das nadadeiras, cocar e adornos: `#D89C42` / `#E87A24`
  - Verde-esmeralda das penas e reflexos da cauda: `#3A9D42`
  - Ciano bioluminescente (magia das águas): `#43F0D3`
  - Cabelo negro profundo: `#181518`
- **Materiais previstos na entrega final:** 1 único material PBR (`MaeDagua_Mat`) com atlas 1024×1024 (Base Color + Normal Map + Roughness/Metallic/Emission controlados por textura), variando `roughness` entre `0.35` (escamas úmidas e ouro) e `0.65` (cabelos e penas).
- **Altura aparente e proporção:** ~7 cabeças de comprimento total desenrolado; em postura ereta apoiada na curva da cauda, **1,82 m de altura total** até a ponta da pena central do cocar (`1,52 m` até o topo da cabeça), condizente com uma unidade lendária de Tier 5.

### 4.2 Separação: Tradição vs. Concept Art vs. Propostas para Elementos Ausentes
- **Vindo diretamente do concept art:** Cocar de 11 penas coloridas com tiara geométrica, cabelos negros longos abertos em ondas, top de escamas verde-azulado, 4 colares de contas sobrepostos, brincos dourados em folha, bracelete triplo no braço direito, nadadeiras pélvicas no quadril, cauda em "S" erguida à direita do corpo e aura ciano nas mãos.
- **Ausente no concept (vista frontal) — Registrado como Proposta para Aprovação:**
  1. **Costas e fechamento do cabelo/top:** Como o concept mostra apenas a vista frontal, propomos cobrir a nuca e o alto das costas com 3 massas de cabelo longo (`BackCascade_L`, `BackCascade_R`, `BackCenter`) descendo até a lombar, sem tiras complexas no top traseiro (coberto pelo cabelo).
  2. **Nadadeira dorsal / quilha posterior da cauda:** Propomos manter as 2 pequenas nadadeiras de quilha lateral/dorsal já visíveis na curva inferior do concept (`BLK_TailRidgeFin_1` e `BLK_TailRidgeFin_2`), sem adicionar nadadeira dorsal nas costas humanas.
  3. **Sustentação no solo (in-game sem água líquida):** No concept, a curva inferior da cauda submerge levemente no rio. Para o tabuleiro 3D da Godot, propomos apoiar o ápice inferior da curva em "S" da cauda diretamente em `Z = 0.0` (origem entre a base de apoio), mantendo a pose 100% estável sem necessidade de plano de água acoplado ao mesh.
  4. **Rig facial:** Conforme seção 7 da especificação (`Shape keys = 0`), propomos controlar cabeça, mandíbula (`jaw`) e pálpebras via bones na Etapa D.

---

## 5. Especificação técnica

- **Status atual:** **Pipeline Completo Concluído (Fase 1 a 10)**.
- **Arquivo de Produção Blender:** `models/mae_dagua/mae_dagua.blend`.
- **Arquivo de Entrega Godot 4.x:** `models/mae_dagua/mae_dagua.glb` (1.36 MB, com malha, rig, materiais, texturas embutidas e 6 Actions NLA).
- **Malha Final:** 1 único objeto de malha unificado (`MaeDagua`), com modificador `Armature` ativo, pivô no chão em `Z = 0.0`.
- **Triângulos Avaliados:** `7.800` triângulos (perfeito enquadramento no orçamento alvo de `6.000–9.000`, teto `15.000`).
- **Materiais PBR:** Exatamente `1` material (`MaeDagua_Mat`) com atlas 1024×1024 + normal map embutidos.
- **Armature & Rig:**
  - **Total de Bones:** `34` bones (dentro do intervalo ideal de `25–45`, teto `60`).
  - **Hierarquia:** `root` (0,0,0) → `pelvis` → coluna (`spine_01` a `03`), pescoço (`neck_01`) e `Head`.
  - **Membros Superiores:** `clavicle_l/r` → `upperarm_l/r` → `lowerarm_l/r` → `hand_l/r` (compatível com `SkeletonProfileHumanoid` da Godot).
  - **Cadeia Ictiomórfica da Cauda:** `tail_01` até `tail_07` → `tail_fin` → leques `fin_outer` e `fin_inner`, com nadadeiras pélvicas (`fin_pelvic_l/r`).
  - **Cadeias Secundárias:** Mechas de cabelo (`hair_l_01/02`, `hair_r_01/02`, `hair_back_01/02`) e penacho do cocar (`cocar`).
  - **Influências por Vértice:** Limitadas estritamente a no máximo 4 pesos (`limit_total = 4`).
- **Animações (6 Clipes NLA sem Root Motion):**
  1. `Idle` (Loop, 48 frames) — Ondulação contínua em "S" da cauda e nadadeiras, respiração serena e postura régia.
  2. `Attack` (One-shot, 26 frames) — Antecipação com recuo da cauda/braço direito, chicoteio fluido de água e retorno ao descanso.
  3. `Stunned` (Loop, 30 frames) — Torso curvado, cabeça baixa e cauda trêmula oscilando em perda momentânea de sustentação.
  4. `Channel` (Loop, 40 frames) — Mãos erguidas entoando o canto hipnótico, expansão torácica e ondulação rítmica da cauda.
  5. `Death` (One-shot, 42 frames) — Perda de força no torso, giro suave e colapso estático sobre a lateral da cauda em Z=0.
  6. `Ability` (*Bênção das Águas*, 52 frames) — Elevação majestosa sobre a base da cauda, abertura ampla dos braços em arco e leque caudal expandido.

---

## 6. Checklist de validação (✅/❌ item por item)

- ✅ **Entradas localizadas e organizadas:** Concept art (`art/concepts/mae_dagua/mae_dagua_concept.png`), xilogravura (`mae_dagua_splash_xilo.jpg`), vídeos (`art/videos/mae_dagua/links.txt`), ficha de lenda (`art/lore/mae_dagua.md`) e ficha de unidade (`docs/units/mae_dagua.md`).
- ✅ **Fase 1 (Pesquisa da lenda):** Concluída com 4 fontes brasileiras independentes, links e data de acesso (`07/11/2026`).
- ✅ **Fase 2 (Análise dos vídeos):** Quadros extraídos em `art/videos/mae_dagua/frames/` e legendas `.vtt` analisadas e documentadas com timestamps.
- ✅ **Fase 3 (Leitura do concept) + Etapa A (Blockout):** Concluído e refinado com a malha `GEO-body_female_stylized` do bundle.
- ✅ **Etapa B (Malha final / Retopo unificado):** Concluída. Objeto único de malha `MaeDagua`, 7.800 triângulos avaliados.
- ✅ **Etapa C (UV e Textura Atlas 1024×1024):** Concluída. Abertura UV sem sobreposição, atlas `mae_dagua_base_color.png` e normal map `mae_dagua_normal.png`.
- ✅ **Etapa D (Rig 25–45 bones e Pesos):** Concluída. Armature limpa com 34 bones, hierarquia compatível com Godot, cadeia de cauda em 8 segmentos, secundários para cabelos/cocar e peso automático limitado a 4 influências por vértice.
- ✅ **Fase 8 (6 Clipes de Animação sem root motion):** Concluída. Clipes `Idle`, `Attack`, `Stunned`, `Channel`, `Death`, `Ability` stashed em NLA tracks individuais.
- ✅ **Fase 9 (Exportação glTF Binary `.glb`):** Concluída. Arquivo `models/mae_dagua/mae_dagua.glb` gerado com sucesso (1.36 MB).
- ✅ **Fase 10 (Validação na Godot 4.x):** Concluída via Godot MCP e resave de recursos sem conflitos de UID.

---

## 7. Renders e Entregáveis

- **Arquivo `.glb` de entrega:** [`models/mae_dagua/mae_dagua.glb`](file:///c:/Users/Professor/Documents/Nohan\mapinguari\pls_nerf_mapinguari\models\mae_dagua\mae_dagua.glb)
- **Arquivo `.blend` fonte:** [`models/mae_dagua/mae_dagua.blend`](file:///c:/Users/Professor/Documents/Nohan\mapinguari\pls_nerf_mapinguari\models\mae_dagua\mae_dagua.blend)
- **Montagem das Animações (Idle, Attack, Channel, Ability):** [`models/mae_dagua/renders/animations_montage.png`](file:///c:/Users/Professor/Documents/Nohan\mapinguari\pls_nerf_mapinguari\models\mae_dagua\renders\animations_montage.png)
- **Apresentação Texturizada e UV:** [`models/mae_dagua/renders/textured_presentation.png`](file:///c:/Users/Professor/Documents/Nohan\mapinguari\pls_nerf_mapinguari\models\mae_dagua\renders\textured_presentation.png)
