# Câmera do tabuleiro

## Controles durante o jogo

| Controle | Ação |
| --- | --- |
| Segurar botão do meio e mover o mouse | Orbitar horizontalmente e mudar a inclinação. Desliga a órbita automática. |
| O | Ligar ou desligar a órbita automática. |
| Home | Voltar suavemente ao enquadramento inicial e desligar a órbita automática. |
| Roda do mouse sobre o campo | Aproximar ou afastar. |

A rotação e o zoom ficam pausados enquanto uma unidade é arrastada. A órbita automática retoma ao soltar a unidade. O scroll sobre os painéis permanece reservado à interface.

## Alterar a posição inicial na Godot

Abra `Scenes/Main/main.tscn` e selecione `Node3D`, que é a instância da cena de câmera. No Inspector, ajuste as propriedades do script `GameCamera`:

- **Initial Yaw Degrees:** rotação em torno do tabuleiro. O padrão `0` mantém o jogador na parte inferior; experimente `15` ou `-15` para uma vista diagonal.
- **Initial Elevation Degrees:** inclinação/altura da vista. O novo padrão é `55` graus; valores maiores deixam o campo mais visto de cima.
- **Initial Distance:** distância ao centro. `0` enquadra automaticamente o tabuleiro e as unidades conforme a janela; um valor positivo fixa a distância inicial, respeitando os limites de zoom.
- **Focus Offset:** deslocamento do ponto observado em relação ao centro do tabuleiro, em coordenadas do mundo.
- **Framing Margin:** espaço livre no enquadramento automático. O padrão é `1.2`; aumente para afastar o campo.
- **Auto Orbit Enabled:** inicia a partida com rotação automática. Desligado por padrão.
- **Auto Orbit Speed:** velocidade em graus por segundo. Valores negativos invertem o sentido.
- **Mouse Sensitivity**, **Min/Max Elevation** e opções de **Zoom:** ajustam a sensação e os limites do controle.

Use essas propriedades para definir a vista inicial: o script calcula o `Transform` do rig ao iniciar e mantém o nó filho `Camera3D` na origem dele. Home recalcula o enquadramento usando o tamanho atual da janela.

O código também oferece `set_auto_orbit(enabled)` e `reset_view()` para conectar futuros botões de interface.
