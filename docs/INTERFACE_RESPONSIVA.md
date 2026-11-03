# Interface responsiva

O jogo adapta o canvas, os painéis e a câmera ao espaço disponível da janela ou da área incorporada no navegador. O redimensionamento também funciona com a partida pausada.

## Escala e proporção

- `canvas_items` preserva a nitidez da interface, enquanto o modo `expand` ocupa proporções diferentes sem esticar as imagens.
- A referência horizontal é **1600 × 900**; a vertical é **800 × 1280**. São medidas de organização do canvas, não uma resolução obrigatória da janela.
- O autoload `ResponsiveLayout` acompanha mudanças de orientação. A escala visual acompanha o tamanho físico e o canvas expande na dimensão excedente.
- A exportação Web já usa `html/canvas_resize_policy=2`, acompanhando a área oferecida pelo navegador. Se o jogo estiver dentro de um iframe de tamanho fixo, esse iframe continua definindo o espaço disponível.

## Comportamentos

- **Menu inicial:** painel central com rolagem se o conteúdo ultrapassar a altura disponível.
- **Regiões:** três cartões em telas largas; abaixo de 1100 unidades de largura do canvas, apenas o cartão central aparece. Setas e teclado continuam navegando por todas as regiões. O fundo cobre a tela sem deformar o retrato.
- **Pausa, opções e tutorial:** painel limitado à área visível, com rolagem interna.
- **Batalha:** informações do topo usam duas linhas em telas estreitas. A loja reorganiza seus controles e mantém as cinco ofertas; o banco distribui suas nove vagas na largura disponível.
- **Sinergias:** painel com altura limitada e rolagem. No modo estreito, começa recolhido e abre pelo botão Sinergias.
- **Inspeção:** painel limitado à altura livre, com conteúdo rolável e botão Fechar.
- **Tooltips:** são reposicionados para permanecer dentro do canvas.
- **Relatório:** tamanho limitado à tela, lista rolável e conteúdo com quebra/truncamento apropriados.
- **Câmera:** calcula o enquadramento usando a área livre entre o topo, as sinergias e o banco. Ao redimensionar, preserva os ângulos e a proporção do zoom manual. Ocultar ou mostrar o HUD mantém a distância e o deslocamento da câmera: somente a interface muda de visibilidade.
- **Animações:** posições de destino do HUD são recalculadas ao redimensionar; transições em andamento são interrompidas para não arrastar painéis para posições antigas.

## Pontos de edição

- `Scripts/UI/responsive_layout.gd`: referências de orientação, ponto de mudança de layout, dimensões da batalha e utilitários de posicionamento.
- `Scripts/UI/game_ui.gd`: disposição dos painéis e controles da batalha.
- `Scripts/UI/bench_ui.gd`, `shop_ui.gd` e `unit_card.gd`: distribuição e tamanho das vagas/cartas.
- `Scripts/UI/main_menu.gd`, `game_overlay.gd` e `combat_report.gd`: menus e relatórios.
- `Scripts/Camera/camera.gd`: enquadramento e deslocamento da câmera para a área livre.

Esta alteração adapta a apresentação; os controles de mouse e teclado continuam os mesmos. Não representa uma conversão completa para controles de toque. As mudanças foram revisadas por leitura do código, sem executar o projeto ou testes nesta etapa.
