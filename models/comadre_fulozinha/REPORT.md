# Comadre Fulozinha (`comadre_fulozinha`) — Relatório de modelagem

## 1. Resumo da lenda (10–20 linhas)

A **Comadre Fulozinha** (ou *Comadre Florzinha*, *Cumade Fulozinha*, *Flor das Matas*) é uma das entidades mais temidas e reverenciadas do folclore brasileiro, com núcleo irradiador na **Zona da Mata, Agreste e Litoral de Pernambuco e da Paraíba**, estendendo-se por Alagoas e Rio Grande do Norte.
Espírito caboclo e guardiã sagrada da flora e da fauna silvestre, é cultuada tanto na tradição oral camponesa quanto na cosmologia indígena (notadamente entre os índios **Potiguara**) e nos ritos da **Jurema Sagrada / Catimbó**, onde é saudada como mestra e guia de abertura dos trabalhos nas matas.
Descrita como uma **jovem cabocla ou menina esguia de cerca de 10 a 12 anos**, possui olhos escuros lampejantes ("cor de jabuticaba") e uma **descomunal cabeleira negra viva** que lhe desce pelas costas e frente do corpo até os joelhos, servindo-lhe simultaneamente de manto e chicote.
Entre suas mechas crescem entrelaçados ramos espinhosos de **urtiga**, cipós retorcidos e pequenas **flores silvestres (*fulô*)**.
Sua presença é precedida por um **assobio fino e misterioso** que obedece a uma temível acústica inversa: quando soa alto e perto, ela está longe; quando soa distante e sussurrado, já se encontra colada às costas da testemunha.
Rege a floresta sob estrita ética de reciprocidade: protege quem pede licença, caça apenas por subsistência e lhe deixa agrados nos tocos de árvore (**papa de aveia ou mandioca sem sal nem pimenta, fumo de rolo e fósforos**).
Em contrapartida, castiga implacavelmente os gananciosos, desmatadores, aqueles que maltratam animais prenhes ou os que ousam insultá-la chamando-a de "Caipora", aplicando-lhes **surras invisíveis e ardidas de cipó e urtiga**, além de fazê-los vagar perdidos em círculos na mata.
Também é famosa por visitar estábulos à noite para cavalgar e deixar **tranças e nós impossíveis de desatar nas crinas dos cavalos**.
**Erros comuns evitados neste projeto:** (1) confundi-la com fadas ou ninfas europeias aladas; (2) sexualizá-la ou atribuir-lhe vestidos coloniais de tecido; (3) misturá-la com o Caipora (montaria em porco ou cachimbo de barro); e (4) retratá-la como monstro bestial sem inteligência ecológica ou sacralidade cabocla.

---

## 2. Fontes (link + data de acesso)

1. **Fundação Joaquim Nabuco (Fundaj) — Pesquisa Escolar:** *Comadre Fulozinha*. Disponível em: https://pesquisaescolar.fundaj.gov.br/pt-br/artigo/comadre-fulozinha/ — Acesso em: 10/11/2026.
2. **CASCUDO, Luís da Câmara.** *Dicionário do Folclore Brasileiro* (verbetes *Comadre Fulozinha*, *Caipora* e *Mãe da Mata*). Global Editora / Síntese em *Portal do Instituto Moreira Salles* e *Fundaj*. Disponível em: https://casadacultura.fundaj.gov.br/ — Acesso em: 10/11/2026.
3. **Universidade Federal da Paraíba (UFPB) / Revista de Estudos Antropológicos e Culturais:** *Comadre Fulozinha e as Narrativas Orais do Território Potiguara e Porto do Capim*. Disponível em: https://periodicos.ufpb.br/ — Acesso em: 10/11/2026.
4. **Governo da Paraíba — Secretaria de Estado da Cultura:** *Patrimônio Imaterial e Tradições Orais da Paraíba: Lendas e Mitos da Zona da Mata e Litoral Norte*. Disponível em: https://paraiba.pb.gov.br/diretas/secretaria-de-cultura/ — Acesso em: 10/11/2026.

---

## 3. Referências audiovisuais analisadas (timestamps + o que foi visto)

Os vídeos de referência foram processados e analisados:

1. **`bwI8MzTOlE0` (*Blender Hair Curves Guide / Sculpt Mode Hair*, t=101s / 01:41):**
   - `01:41` (101s): Separação de geometria do couro cabeludo/escalpo (`Shift+D` + `P > Selection`) para servir como base de fixação e evitar lacunas na raiz.
   - Adição de objeto de curvas de cabelo (`Curve > Empty Hair` associado ao escalpo).
   - Uso de `Curves Sculpt Mode` com as ferramentas `Add` e `Comb`, organizando as curvas estritamente de baixo para cima (*bottom-to-top*: nuca $\to$ dorso médio $\to$ laterais $\to$ topo da coroa $\to$ franja frontal) para impedir embaraçamento e penetração no tronco.
   - Para modelos em engines em tempo real (Godot 4.x), as mechas são convertidas em malha poligonal fechada com chanfro (*bevel*) estilizado, gerando silhuetas nítidas com perfil triangular/diamante e pontas afiladas.

2. **`ethg2nYSjqg` (*How to create FAST Stylized Hair/Fur in Blender 4.0*, ItsPaulTodd, 06:09):**
   - `00:35` a `01:03`: Configuração de curva guia (Path) associada a um objeto de bisel 2D (*Bevel > Object*) fechado com perfil estilizado em diamante/crista (*Bezier Circle* editado).
   - `01:27` a `02:30`: Manipulação de pontos de controle do perfil para criar crista afilada no topo (vértice em `Vector`), flancos curvos e base plana que se apoia suavemente sobre o crânio/corpo.
   - `02:50` a `03:30`: Uso do atalho `Alt + S` nos pontos da curva para controlar o raio (`radius = 0.0` nas pontas para término em ponta afilada perfeita, e expansão volumosa no ventre da mecha).
   - `04:30` a `05:10`: Uso de `Ctrl + T` (*Tilt*) para orientar a crista externa em direção à luz e à silhueta, mantendo o fundo plano rente ao crânio.
   - `05:35`: Conversão das curvas em malha (*Convert to Mesh*) com junção unificada e acabamento escultural sem partículas pesadas.
   - **Aplicação direta neste modelo:** Todas as mechas da Comadre Fulozinha foram estruturadas seguindo a hierarquia de camadas do vídeo `bwI8MzTOlE0&t=101s` combinada com o perfil chanfrado estilizado com crista facetada do vídeo `ethg2nYSjqg`: franja frontal leve terminando estritamente acima das sobrancelhas ($Z \ge 1.24\text{ m}$), mechas laterais emoldurando as têmporas e bochechas sem obstruir a face, mechas frontais descendo pelos lados do peito e manto posterior com mechas em cascata até as panturrilhas, com zero clipagem validada via BVH Tree.

3. **`qSR-qK2vRQY` (*Base Meshes Asset Bundle*, Joey Carlino, 03:33):**
   - Adaptação anatômica da malha `GEO-body_female_stylized` para o biotipo juvenil (1,35 m de altura e 5,8 cabeças de proporção).

4. **`m-Obo_nC3SM` (*Rigging for Beginners*, Joey Carlino, 59:26):**
   - Planejamento de rig para o prop acessório do chicote de cipó e cadeias secundárias de cabelo.
- **Declaração de limitação e vocabulário de movimento:** Como não existem animações prévias da Comadre Fulozinha no repositório, o vocabulário de movimento foi inferido a partir da rica tradição oral e da ficha de gameplay (`resources/units/comadre_fulozinha.tres`): postura ágil em semi-agachamento no repouso, chicoteio cortante com estalo seco no ataque, assobio místico na canalização e giro aéreo com espiral de urtiga na conjuração de sua habilidade em área (*Invocação da Floresta*).

---

## 4. Decisões de arte (o que veio do texto, o que foi escolha/proposta)

### 4.1 Checklist de leitura do texto canônico (`art/lore/comadre_fulozinha.md`)
- **Silhueta dominante:** Menina cabocla ágil envolta pelo manto espesso de sua própria cabeleira negra viva com urtigas e flores, empunhando chicote de cipó espinhoso.
- **Formas-base:** Cone invertido (manto de cabelo), linha curva helicoidal (chicote de cipó) e detalhes orgânicos recortados (folhas de urtiga denteadas e flores silvestres).
- **Paleta canônica:**
  - Cabeleira viva: `#161314` (preto profundo/terra úmida)
  - Pele cabocla acobreada: `#7E482B`
  - Urtiga e cipó: `#2F5227` e `#4B3621`
  - Flores silvestres (*fulô*): `#D48B28` e `#E0C068`
  - Olhos de jabuticaba: `#0C080E` faiscante

### 4.2 Propostas autorais e refinamentos de blockout (Fase 4 - Iteração 2)
1. **Malha contínua de cabelo estilizado (`GEO_Hair`):**
   - Construção de volume craniano natural adaptado à caixa craniana da malha-base, franja estilizada com três mechas cônicas triangulares sobre as sobrancelhas, mechas laterais/frontais descendo sobre as clavículas/tórax e um manto posterior contínuo em quads com 7 canaletas e pontas afiladas até a altura das panturrilhas.
   - Aplicação de algoritmo anti-clipagem via BVH Tree da malha corporal, garantindo margem mínima de 15 mm a 20 mm e **zero penetração** no corpo, braços ou dorso.
2. **Chicote como acessório que a personagem usa (`Acessorio_Chicote`):**
   - O chicote é um prop/acessório independente (coleção `PROPS`), composto por empunhadura anatômica de cipó/madeira na palma da mão direita, pomo de retenção, anel de fixação e corpo dinâmico de cipó com nós espinhosos de urtiga e ponta em espiral no chão.
3. **Manto vivo de cabelo como vestimenta:**
   - Em conformidade com as fontes orais de Câmara Cascudo e da Paraíba/Pernambuco, a nudez juvenil é velada pelas densas camadas da cabeleira viva entrelaçada a cipós, folhas de urtiga e flores silvestres.

---

## 5. Especificação técnica e Resultados Finais (Etapas B, C, D & Godot)

### 5.1 Etapa B — Retopologia e UV
- **Objeto final:** Malha unificada `ComadreFulozinha` (corpo juvenil, olhos, escalpo, mechas estilizadas, folhas de urtiga, flores e chicote de cipó).
- **Contagem de Triângulos:** **7.799 triângulos** (dentro da meta rigorosa de 6.000–9.000 tris, bem abaixo do teto de 15.000).
- **Abertura de UV:** UV unificado em tile único [0, 1] com `island_margin = 0.005` e empacotamento otimizado.

### 5.2 Etapa C — Texturização PBR
- **Material Único:** `Fulozinha_Mat` (`Principled BSDF` com atlas de textura).
- **Texturas geradas (1024×1024 PNG):**
  - Base Color: `textures/comadre_fulozinha_base_color.png` (bake difuso completo da pele cabocla, mechas pretas, cipó, urtigas e flores).
  - Normal Map: `textures/comadre_fulozinha_normal.png` (micro-texturas orgânicas e relevo foliar em espaço tangente).
- **Painel de Validação Texturizada:** `renders/textured_presentation.png`.

### 5.3 Etapa D — Rigging e Animação
- **Armature:** `Fulozinha_Armature` com **34 bones** (meta de especificação: 25–40):
  - Cadeia vertebral e cabeça: `root`, `pelvis`, `spine_01`, `spine_02`, `spine_03`, `neck_01`, `Head`.
  - Membros inferiores: `thigh_l/r`, `shin_l/r`, `foot_l/r`, `toe_l/r`.
  - Membros superiores: `clavicle_l/r`, `upperarm_l/r`, `lowerarm_l/r`, `hand_l/r`.
  - Cadeia secundária do chicote: `whip_grip`, `whip_01`, `whip_02`, `whip_03`, `whip_04`, `whip_tip`.
  - Cadeia secundária do cabelo vivo: `hair_front_l/r`, `hair_back_01`, `hair_back_02`, `hair_back_03`.
- **Pesos:** Vinculação automática refinada e limitada estritamente a **$\le 4$ pesos por vértice**.
- **Contrato de 6 Animações NLA (sem root motion):**
  1. `Idle` (Loop, 48f, 2.0s): postura ágil de cabocla em semi-agachamento, respiração e ondulação suave do chicote e mechas.
  2. `Attack` (One-shot, 24f, 1.0s): chicotada cortante com recuo ágil da mão direita.
  3. `Stunned` (Loop, 36f, 1.5s): recuo cambaleante atordoado e desequilíbrio leve.
  4. `Channel` (Loop, 36f, 1.5s): invocação mística com a mão esquerda erguida e postura de assobio da mata.
  5. `Death` (One-shot, 36f, 1.5s): queda de joelhos com desfalecimento e chicote repousando no chão.
  6. `Ability` (One-shot, 48f, 2.0s): *Invocação da Floresta* com salto giratório de 360° e espiral centrífuga do chicote de urtiga.
- **Painel de Animações:** `renders/animations_montage.png`.

### 5.4 Integração na Godot Engine 4.x
- **Arquivo Exportado:** `models/comadre_fulozinha/comadre_fulozinha.glb` (com NLA tracks, skins, esqueleto e materiais embutidos).
- **Importação e UID:** `models/comadre_fulozinha/comadre_fulozinha.glb.import` registrado com `UID` canônico no projeto.
- **Resource Atualizado:** `resources/units/comadre_fulozinha.tres` vinculado a `model_scene = ExtResource("2_model")`.
- **Verificação Automatizada:** `tests/test_comadre_fulozinha_model.gd` executado com sucesso no Godot 4.6.3 headless:
  - Spawning via `UnitSpawner.spawn_unit_from_stats("comadre_fulozinha")`.
  - `AnimationPlayer` localizado com todas as 6 ações validadas.
  - Reprodução funcional testada para todos os estados de combate (`Idle`, `Attack`, `Ability`, `Stunned`, `Death`).

