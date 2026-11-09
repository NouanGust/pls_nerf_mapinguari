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

- **Status atual:** Checkpoint Fase 1–3 + Etapa A (**Blockout concluído** em `models/mae_dagua/mae_dagua_blockout.blend`).
- **Triângulos (Blockout avaliado):** `8.404` triângulos (dentro do orçamento alvo de `6.000–9.000` triângulos, teto `15.000`).
- **Objetos no Blockout:** 75 primitivas blocadas na coleção `GEO` (serão fundidas em `1` malha única `MaeDagua` na Etapa B — Retopo/Malha Final).
- **Bones (planejado para Etapa D):** ~34 bones (alvo `25–45`, máx. 4 influências/vértice): `root` → `hips` → cadeia de coluna/cabeça/mandíbula, braços/mãos, cadeia de 8 bones para a cauda em "S" + nadadeira caudal, e cadeias secundárias para cabelos e nadadeiras laterais.
- **Materiais (meta final):** `1` material PBR com atlas `1024×1024` (atualmente 14 materiais simples de cor sólida apenas para separação visual de blockout).
- **Clipes planejados (Etapa E):** `Idle` (loop), `Attack`, `Stunned` (loop), `Channel` (loop), `Death`, `Ability`.

---

## 6. Checklist de validação (✅/❌ item por item)

- ✅ **Entradas localizadas e organizadas:** Concept art (`art/concepts/mae_dagua/mae_dagua_concept.png`), xilogravura (`mae_dagua_splash_xilo.jpg`), vídeos (`art/videos/mae_dagua/links.txt`), ficha de lenda (`art/lore/mae_dagua.md`) e ficha de unidade (`docs/units/mae_dagua.md`).
- ✅ **Fase 1 (Pesquisa da lenda):** Concluída com 4 fontes brasileiras independentes, links e data de acesso (`07/11/2026`).
- ✅ **Fase 2 (Análise dos vídeos):** Quadros extraídos em `art/videos/mae_dagua/frames/` e legendas `.vtt` analisadas e documentadas com timestamps.
- ✅ **Fase 3 (Leitura do concept) + Etapa A (Blockout):** Arquivo `models/mae_dagua/mae_dagua_blockout.blend` gerado via Blender 4.5 headless, com `8.404` triângulos avaliados, escala e rotação aplicadas, sem escala negativa.
- ✅ **Comparação visual de Blockout:** Renders de frente (`blockout_front.png`), perfil (`blockout_side.png`), 3/4 (`blockout_three_quarter.png`) e prancha lado a lado com o concept (`blockout_comparison.png`) gerados em `models/mae_dagua/renders/`.
- ⏳ **Etapa B (Malha final / Retopo unificado):** Aguardando aprovação do checkpoint de blockout.
- ⏳ **Etapa C (UV e Textura Atlas 1024×1024):** Aguardando aprovação do checkpoint de blockout.
- ⏳ **Etapa D (Rig 25–45 bones e Pesos):** Aguardando aprovação.
- ⏳ **Fase 8 (6 Clipes de Animação sem root motion):** Aguardando aprovação.
- ⏳ **Fase 9 e 10 (Export `.glb` e validação na Godot 4.x):** Aguardando aprovação.

---

## 7. Limitações e pendências

1. **Vídeos de referência (`docs/Links_videos_modelagem.txt`):** Tratam-se de tutoriais de modelagem, malhas-base e rigging no Blender (Joey Carlino), e não de vídeos específicos da lenda Mãe d'Água. As referências de movimento aquático foram definidas a partir da pesquisa folclórica e da leitura da arte conceitual.
2. **Aprovação das propostas de costas e base da cauda (Seção 4.2):** Necessária confirmação humana sobre o fechamento traseiro do cabelo/top e o apoio direto da curva da cauda em `Z = 0` antes de prosseguir para a unificação da malha final (Etapa B).

---

## 8. Próximos passos sugeridos

1. Revisar e aprovar o **Blockout** (`models/mae_dagua/renders/blockout_comparison.png`) e as propostas para os elementos ausentes na vista frontal (costas cobertas pelo cabelo e curva da cauda apoiada em `Z = 0`).
2. Com o seu "ok" (ex.: `continua do blockout`), avançar para a **Etapa B e C**: unificar e retopologizar a malha final (`6.000–9.000` triângulos), abrir UV única sem sobreposição e gerar o atlas de textura `1024×1024` (`base_color` + `normal_map`).
3. Seguir para **Etapa D (Rig)**, **Fase 8 (Animações: Idle, Attack, Stunned, Channel, Death, Ability)** e **Fase 9–10 (Export `.glb` e validação na Godot)**.
