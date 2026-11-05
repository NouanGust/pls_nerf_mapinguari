# Arena de Autochess na Mata Atlântica — Documentação de Entrega (`MATA_ATLANTICA_ENV`)

## 1. Ambiente de Execução e Motor de Renderização

- **Versão do Blender:** `Blender 5.2.2 LTS` (`hash d13f752e3b9c`)
- **Motor de Renderização:** `Cycles` (GPU `NVIDIA RTX A400` via OptiX/CUDA com Denoising ativo)
- **Gerenciamento de Cor:** `AgX` / `Filmic` (`exposure = 0.22`), sem pós-processamento destrutivo no compositor

---

## 2. Parâmetros Utilizados (`CONFIG` em `build_mata_atlantica.py`)

| Parâmetro | Valor Executado |
|---|---|
| Nome da cena | `MataAtlantica_Autochess` |
| Coleção principal | `MATA_ATLANTICA_ENV` |
| Unidade de trabalho | Metro (`METRIC`, escala `1.0`) |
| Eixo vertical | `Z` |
| Frente / Reserva | `Y negativo` |
| Fundo / Floresta / Passagem | `Y positivo` |
| Colunas × Fileiras de hexágonos | `8 × 8` (**64 casas individuais**: `Board_Hex_00_00` a `Board_Hex_07_07`) |
| Raio do hexágono (`R`) | `0,65 m` (orientação **ponta para cima**) |
| Espaçamento horizontal / vertical | `sqrt(3) * R = 1,1258 m` / `1,5 * R = 0,975 m` (meia célula em linhas ímpares) |
| Sulcos das casas e da reserva | Largura `0,025 m` e profundidade visual `0,012 m` (escavados na terra úmida, sem emissão) |
| Posições de reserva frontal | **9 posições individuais** (`Reserve_Slot_00` a `Reserve_Slot_08`) |
| Semente aleatória fixa | `42` |
| Resolução Prévia / Final | `960 × 540` (`36 samples`) / `1920 × 1080` (`112 samples`, PNG) |
| Câmera principal (`Camera_Game`) | Lente `47 mm`, perspectiva 3/4 elevada, ocupação horizontal do conjunto jogável em `~56%–60%` |

---

## 3. Organização da Hierarquia (`MATA_ATLANTICA_ENV`)

A cena foi estruturada integralmente dentro da coleção `MATA_ATLANTICA_ENV`, preservando os objetos separados e editáveis nas 12 subcoleções exigidas pela Seção 5 do documento:

1. `00_CONTROLS`: `Control_Board_Center` (alvo de referência na origem).
2. `01_TERRAIN`: `Terrain_Main` (superfície contínua de solo florestal úmido de `76 m × 76 m` integrando o campo plano, a reserva frontal, a depressão suave do riacho esquerdo e a encosta ascendente da Serra do Mar ao fundo) e `Terrain_MossyBorderStones` (borda baixa orgânica de pedras musgosas contornando a reserva e o campo).
3. `02_BOARD`: 64 objetos individuais (`Board_Hex_00_00` a `Board_Hex_07_07`) com sulcos escavados na terra batida úmida, variação sutil de umidade por casa e metadados `grid_col` e `grid_row`.
4. `03_RESERVE`: 9 objetos individuais (`Reserve_Slot_00` a `Reserve_Slot_08`) no lado `Y negativo`, nivelados ao mesmo solo e integrados à borda musgosa.
5. `04_TREES`: 5 variantes botânicas (`Tree_Variant_A` a `Tree_Variant_E`: figueira com raízes tabulares/sapopemas, Pau-Brasil nodoso, Palmito-Juçara com coroa de folhas arqueadas, árvore inclinada de encosta e troncos gêmeos entrelaçados) distribuídas em 3 camadas de profundidade e cantos de moldura frontal.
6. `05_CANOPY`: massas de copa elevada (`Canopy_Cluster_*`) que filtram o luar e mantêm o conceito de **mata fechada** sem obstruir nenhuma casa, além de feixes diagonais sutis de luar filtrado (`Moonbeam_Shaft_01..03`).
7. `06_UNDERGROWTH`: agrupamentos orgânicos de samambaias (`Fern_Cluster_*`), plantas tropicais de folhas largas úmidas (`Broadleaf_Cluster_*`), bromélias em roseta com brácteas rubras discretas (`Bromeliad_Cluster_*`) e manchas de folhas mortas caídas (`FallenLeaves_Patches`).
8. `07_ROOTS_AND_VINES`: raízes superficiais tortuosas (`Root_00..07`) emergindo da base das árvores nas bordas e variantes de cipós pendentes (`Vine_Variant_A..C`) suspensos em curvas catenárias naturais.
9. `08_STREAM_AND_ROCKS`: riacho estreito de água escura na margem esquerda (`Stream_Surface`) e 4 variantes de pedras musgosas (`Rock_Mossy_A..D`) com musgo nas faces superiores e toque discreto de líquens amarelados na rocha chumbo molhada.
10. `09_HORROR_DETAILS`: os três indícios de horror ambiental (Seção 15) + vestígio humano discreto (Seção 16):
    - **A. Pegadas de orientação suspeita:** `Horror_Footprint_00..05` na lama próxima ao riacho esquerdo, com dedos voltados no sentido oposto ao avanço, desaparecendo entre as raízes.
    - **B. Cipós em nós improváveis:** `Horror_ImpossibleVineKnot` na lateral direita, sem formar símbolos artificiais.
    - **C. Passagem que parece retornar:** `Horror_ReturningMudTrail` + repetição espacial de dois troncos inclinados em arco e pedra musgosa (`Horror_RepeatingPassage_Near` e `Horror_RepeatingPassage_Far`) ao fundo.
    - **D. Vestígio humano discreto:** `Horror_FadedCloth` (pequeno pedaço de tecido desbotado e manchado de barro preso em galho baixo próximo à passagem).
11. `10_LIGHTS`: 4 camadas de luz noturna (`Light_Moon_Key`, `Light_Ambient_Fill`, `Light_Wet_Specular_Rim` e `Light_Canopy_Back`).
12. `11_CAMERAS`: `Camera_Game` configurada sem profundidade de campo destrutiva para nitidez integral das 64 casas e das 9 posições de reserva.

---

## 4. Decisões de Implementação e Limitações Registradas

- **Conceito Espacial de Mata Fechada:** As copas altas (`05_CANOPY`) e as três camadas de árvores (`04_TREES`) fecham o espaço ao redor e acima da cena, filtrando o luar sem transformar o ambiente em clareira aberta e sem invadir o corredor visual entre `Camera_Game` e o conjunto jogável.
- **Materiais Procedurais Nativos:** Todos os materiais foram construídos com nós nativos do Shader Editor do Blender (`Principled BSDF`, `ShaderNodeTexNoise`, `ShaderNodeNewGeometry`, `ShaderNodeObjectInfo`, `ShaderNodeBump`), garantindo independência de ativos externos pagos.
- **Não Exportação Automática:** Conforme a regra da Seção 27 (*"Não exporte para um motor de jogo sem solicitação adicional"*), esta geração produziu exclusivamente os entregáveis nativos do Blender (`.blend`, renders `.png`, `build_mata_atlantica.py` e `README.md`).

---

## 5. Localização dos Arquivos Entregues

Todos os entregáveis encontram-se no diretório `output/mata_atlantica_autochess/`:

1. `output/mata_atlantica_autochess/mata_atlantica_autochess.blend`
2. `output/mata_atlantica_autochess/mata_atlantica_autochess_final.png` (`1920 × 1080`)
3. `output/mata_atlantica_autochess/mata_atlantica_autochess_preview.png` (`960 × 540`)
4. `output/mata_atlantica_autochess/build_mata_atlantica.py`
5. `output/mata_atlantica_autochess/README.md`

