# Alpha: Anhangá e tabuleiro no Blockbench

Status em 2026-10-20: preparação concluída; modelagem, texturas e animações ainda não produzidas.

## Conexão para retomar

O plugin `blockbench-mcp@blockbench-mcp-project` 1.9.1 foi instalado. `codex mcp list` informa `blockbench-headless` e `blockbench` habilitados, mas nenhuma ferramenta Blockbench está disponível nesta conversa. Não foi encontrado processo Blockbench aberto.

Reiniciar o Codex e retomar esta conversa ou iniciar uma nova conversa neste projeto para carregar o plugin. Verificar as ferramentas antes de criar arquivos. Não adicionar outro registro MCP sem diagnosticar o existente.

O registro headless observado usa `npx -y github:jasonjgardner/blockbench-mcp-plugin#v1.9.1 --root .`. Confirmar que a raiz corresponde a este projeto. Se houver erro de inicialização no Windows, verificar a necessidade de `cmd /c npx` conforme o README do plugin.

## Direção do Anhangá

Referência visual: `Assets/Units_teste/Anhangá.png`. Cervo branco quente com sombras malva, pescoço alongado, focinho cervídeo, galhadas ramificadas marrom/marfim, cascos escuros, olhos vermelho-âmbar e marca dourada frontal. Preservar a silhueta legível na câmera do tabuleiro. A mandíbula deve permitir o Rugido da Floresta.

Decisões iniciais de produção, ainda não medidas em um modelo:

- Destino: Godot 4.6, alpha Windows do Folchess; múltiplas unidades em tela.
- Fonte editável: Generic Model (`free`) `.bbmodel`.
- Entrega de runtime pretendida: glTF/GLB com materiais e clips, dependente de confirmar exportador que preserve animações. OBJ não atende à entrega animada.
- Orçamento proposto: até 1.500 triângulos; concentrar geometria nas galhadas e articulações.
- Escala de trabalho proposta: 16 unidades Blockbench = 1 unidade Godot.
- Volume de repouso: aproximadamente 1,65 de comprimento, até 1,6 de largura das galhadas e até 1,9 de altura; confirmar proporções no blockout e comparação com demais unidades.
- Origem nos pés, centro da base em X/Z. Frente final em +Z, conforme as unidades atuais; conferir conversão na exportação.
- Shading estilizado facetado, atlas 256 × 256, sem normal map. Materiais opacos; emissão apenas para olhos/marca se suportada e verificada.
- Animação por transformações de grupos rígidos com pivôs nas articulações. Evitar root motion.

## Divisão do trabalho

- Agente principal: conexão, blockout/modelagem do Anhangá, integração e validação.
- Subagente de texturas: `anhanga_texture_plan.md`.
- Subagente de animação: `anhanga_animation_plan.md`.
- Subagente de cenário e objetos: `board_bench_model_plan.md`.

Após o blockout aprovado por inspeção, fornecer cópias separadas aos agentes de textura e animação. Não permitir gravação concorrente no mesmo `.bbmodel`. Consolidar com revisões verificadas, preservando UUIDs de grupos, texturas e animações.

## Verificações pendentes

1. Conexão headless e acesso à raiz correta.
2. Silhueta do Anhangá em frente, lateral e três quartos.
3. UVs e texturas, sem distorções; orçamento real de triângulos e materiais.
4. Poses de cada clip e emenda dos loops, sem cascos atravessando o chão.
5. Exportação e importação no Godot preservando orientação, pivôs, materiais e clips.
6. Substituição específica do visual de `anhanga`, sem afetar as outras unidades.
7. Compatibilidade do tabuleiro/banco com posicionamento e seleção existentes.
8. Testes de combate e inspeção visual na câmera real.

Nenhuma dessas verificações de assets foi executada: os assets ainda não existem.
