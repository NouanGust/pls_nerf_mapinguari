# Pantanal Autochess — Arena 3D de Horror Folclórico

Cena 3D procedural do bioma Pantanal ao entardecer desenvolvida para o jogo de autochess de horror folclórico brasileiro.

## 1. Especificações Técnicas
- **Versão do Blender**: 5.2.2 LTS
- **Motor de Renderização**: Cycles (GPU)
- **Gerenciamento de Cor**: Filmic / Medium Contrast
- **Resolução Final**: 1920 × 1080 (16:9)
- **Coleção Raiz**: `PANTANAL_ENV` (subcoleções `00_CONTROLS` a `11_CAMERAS`)

## 2. Estrutura da Cena e Parâmetros
- **Grade Hexagonal**: 8 colunas × 8 fileiras (64 casas), raio `R = 0.65 m`, pointy-topped.
- **Ladrilhos Planos**: Superfície dos hexágonos 100% plana com sulcos rasos de 0.026 m e profundidade de 0.012 m esculpidos na terra batida de vazante pantaneira.
- **Reserva Frontal**: 9 posições retangulares alinhadas na frente (`Y < 0`), integradas à mesma terra firme.
- **Água e Canais**: Canais de vazante ao fundo e à esquerda (`Z = -0.16 m`), com água escura e reflexos quentes de cobre/âmbar.
- **Vegetação**: Touceiras de capim pantaneiro e folhas aquáticas flutuantes (aguapés e vitórias-régias jovens).
- **Elementos Rurais**: Cerca de mourões de aroeira com arame farpado frouxo e canoa de madeira tradicional abandonada encalhada na margem.
- **Horror Ambiental Sutil**:
  1. `Horror_ExtraBranchReflection`: Ramo submerso anômalo visível no reflexo da água sob a árvore lateral.
  2. `Horror_SubmergedWake`: Ondulações concêntricas de esteira recente ao lado da canoa vazia.
  3. `Horror_FlattenedGrassTrail`: Trilha de capim amassado que entra na água e ressurge na margem oposta.
- **Iluminação de Entardecer**: Sol poente âmbar/cobre baixo vindo de trás e à esquerda (`Light_Sunset_Key`), preenchimento suave frio (`Light_Cool_Fill`), e céu físico de entardecer pantaneiro.

## 3. Arquivos Entregues
- `pantanal_autochess.blend` — Cena completa editável e organizada.
- `pantanal_autochess_final.png` — Render final 1920 × 1080.
- `pantanal_autochess_preview.png` — Render de prévia 960 × 540.
- `build_pantanal.py` — Script completo de automação em Blender Python.
