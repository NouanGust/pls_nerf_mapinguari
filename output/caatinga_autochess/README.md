# Arena de Autochess na Caatinga — Documentação de Entrega (`CAATINGA_ENV`)

## 1. Ambiente de Execução e Motor de Renderização

- **Versão do Blender:** `Blender 5.2.2 LTS` (`hash d13f752e3b9c`)
- **Motor de Renderização:** `Cycles` (GPU `NVIDIA RTX A400` via OptiX/CUDA com Denoising ativo)
- **Gerenciamento de Cor:** `AgX` / `Filmic` (`exposure = 0.15`), sem pós-processamento destrutivo no compositor

---

## 2. Parâmetros Utilizados (`CONFIG` em `build_caatinga.py`)

| Parâmetro | Valor Executado |
|---|---|
| Nome da cena | `Caatinga_Autochess` |
| Coleção principal | `CAATINGA_ENV` |
| Unidade de trabalho | Metro (`METRIC`, escala `1.0`) |
| Eixo vertical | `Z` |
| Frente / Reserva | `Y negativo` |
| Fundo / Floresta / Trilha | `Y positivo` |
| Colunas × Fileiras de hexágonos | `8 × 8` (**64 casas individuais**: `Board_Hex_00_00` a `Board_Hex_07_07`) |
| Raio do hexágono (`R`) | `0,65 m` (orientação **ponta para cima**) |
| Espaçamento horizontal / vertical | `sqrt(3) * R = 1,1258 m` / `1,5 * R = 0,975 m` (meia célula em linhas ímpares) |
| Sulcos das casas e da reserva | Largura `0,024 m` e profundidade visual `0,012 m` (escavados na terra, sem emissão) |
| Posições de reserva frontal | **9 posições individuais** (`Reserve_Slot_00` a `Reserve_Slot_08`) |
| Semente aleatória fixa | `42` |
| Resolução Prévia / Final | `960 × 540` (`32 samples`) / `1920 × 1080` (`96 samples`, PNG) |
| Câmera principal (`Camera_Game`) | Lente `48 mm`, perspectiva 3/4 elevada, ocupação horizontal do conjunto jogável em `~56%–58%` |

---

## 3. Organização da Hierarquia (`CAATINGA_ENV`)

A cena foi estruturada integralmente dentro da coleção `CAATINGA_ENV`, preservando os objetos separados e editáveis nas 11 subcoleções exigidas:

1. `00_CONTROLS`: `Control_Board_Center` (alvo de referência na origem).
2. `01_TERRAIN`: `Terrain_Main` (superfície contínua de `76 m × 76 m` integrando campo plano, reserva frontal, barrancos suaves nas laterais e trilha erodida ao fundo).
3. `02_BOARD`: 64 objetos individuais (`Board_Hex_00_00` a `Board_Hex_07_07`) com sulcos rasos escavados e metadados `grid_col` e `grid_row`.
4. `03_RESERVE`: 9 objetos individuais (`Reserve_Slot_00` a `Reserve_Slot_08`) no lado `Y negativo`, nivelados ao mesmo solo e sem degraus ou pedestal.
5. `04_WHITE_FOREST`: 5 variantes botânicas (`Tree_Pale_Variant_A` a `Tree_Pale_Variant_E`) distribuídas em múltiplas camadas nas laterais e no fundo, respeitando a máscara de exclusão de `0,65 m` + raio da copa.
6. `05_CACTI`: 3 variantes de cactos colunares (`Cactus_Columnar_Variant_A`, `B` e `C`: coluna simples, coluna com ramificação e grupo de colunas) em verde-oliva escuro fosco com sulcos longitudinais.
7. `06_UNDERGROWTH`: manchas orgânicas de tufos de capim seco (`Undergrowth_Tuft_*`) e pedras irregulares (`Undergrowth_Rock_*`) nas bordas externas.
8. `07_FENCE_AND_SKULL`: mourão principal rachado (`Fence_Post_Skull`), postes inclinados (`Fence_Post_01..03`), segmentos de arame farpado antigo (`Fence_Wire_Segments`) e **uma única caveira bovina envelhecida** (`Skull_Bovine`) posicionada no terço médio esquerdo da composição.
9. `08_HORROR_DETAILS`: as três anomalias discretas de horror ambiental:
   - **A. Caminho que parece retornar:** `Horror_ReturningTrail` + repetição parcial de dois troncos inclinados e pedra de marco (`Horror_LoopPath_Near` e `Horror_LoopPath_Far`).
   - **B. Galhos presos em nós improváveis:** `Horror_KnottedBranches` na lateral direita, sem formar símbolos ou letras.
   - **C. Marcas que cessam na poeira:** `Horror_DustTrack_00..04` próximas ao mourão da caveira, interrompendo-se abruptamente antes da área de jogo.
10. `09_LIGHTS`: `Light_Sunset_Key` (luz solar rasante de fim de tarde vinda da esquerda e de trás em tom âmbar/cobre moderado) e `Light_Sky_Fill` (preenchimento frio e amplo para leitura nítida de todas as casas e sulcos).
11. `10_CAMERAS`: `Camera_Game` configurada sem profundidade de campo destrutiva para nitidez integral das 64 casas e das 9 posições de reserva.

---

## 4. Decisões de Implementação e Limitações Registradas

- **Preservação de Conteúdo Preexistente:** O script `build_caatinga.py` oculta objetos fora de `CAATINGA_ENV` sem apagá-los e reconstrói apenas a coleção `CAATINGA_ENV` em caso de reexecução, evitando duplicatas.
- **Materiais Procedurais Nativos:** Todos os materiais foram construídos com nós nativos do Shader Editor do Blender (`Principled BSDF`, `ShaderNodeTexNoise`, `ShaderNodeTexVoronoi`, `ShaderNodeObjectInfo`, `ShaderNodeBump`), garantindo independência de texturas pagas ou downloads externos.
- **Não Exportação Automática:** Conforme a regra da Seção 21 (*"Não exporte para um motor de jogo sem solicitação adicional"*), esta geração produziu exclusivamente os entregáveis nativos do Blender (`.blend`, renders `.png`, `build_caatinga.py` e `README.md`), sem sobrescrever os arquivos anteriores do projeto.

---

## 5. Localização dos Arquivos Entregues

Todos os entregáveis encontram-se no diretório `output/caatinga_autochess/`:

1. `output/caatinga_autochess/caatinga_autochess.blend`
2. `output/caatinga_autochess/caatinga_autochess_final.png` (`1920 × 1080`)
3. `output/caatinga_autochess/caatinga_autochess_preview.png` (`960 × 540`)
4. `output/caatinga_autochess/build_caatinga.py`
5. `output/caatinga_autochess/README.md`

