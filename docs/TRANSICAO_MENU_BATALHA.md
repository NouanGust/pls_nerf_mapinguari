# Entrada cinematográfica na batalha

Ao iniciar ou continuar uma região pelo menu:

1. O menu escurece até preto em 0,5 segundo.
2. A batalha monta o tabuleiro, aplica o ambiente regional e cria ou restaura a campanha com a tela ainda preta.
3. A imagem reaparece em 0,65 segundo, enquanto a câmera faz a apresentação.
4. Ao chegar ao enquadramento de jogo, a interface e os controles são liberados.

## Qual apresentação aparece

- **Primeira visita:** região sem arquivo de campanha e no round 1. A câmera começa acima do tabuleiro e desce suavemente até a posição de jogo.
- **Retorno à região:** existe uma campanha salva, inclusive no round 1 ou já encerrada, ou o round atual é maior que 1. A câmera aproxima uma unidade aleatória em campo, permanece brevemente nela e volta ao enquadramento de jogo.
- A escolha considera unidades vivas dos dois times; unidades no banco ficam fora do sorteio. Se o campo estiver vazio, usa a descida.
- A apresentação acontece ao entrar pelo menu, não em cada mudança de round. Executar diretamente a cena de batalha no editor mantém a entrada direta.

A presença do arquivo é consultada antes de salvar a nova entrada. Não foi acrescentado um campo obrigatório aos saves existentes.

## Ajustes no Godot

Na cena `Scenes/Main/main.tscn`, selecione o nó `Node3D` que contém `Camera3D`. No script da câmera, o grupo **Entrada na batalha** expõe:

| Propriedade | Padrão | Função |
| --- | --- | --- |
| Entry Descent Seconds | 3,2 s | Duração da descida |
| Entry Height Multiplier | 1,8 | Altura inicial em relação à distância de jogo |
| Entry Closeup Seconds | 1,2 s | Tempo de aproximação da unidade; o retorno usa esse tempo + 0,4 s |
| Entry Hold Seconds | 0,6 s | Pausa no destaque da unidade |
| Entry Unit Distance | 6 | Distância da câmera à unidade |

O destino continua seguindo **Enquadramento inicial**, o tamanho da janela e o espaço reservado ao HUD. A preferência de órbita automática é retomada depois da apresentação.

## Organização

- `Scripts/UI/battle_transition.gd`: cortina preta em CanvasLayer 200; intercepta entradas até o fim da apresentação.
- `Scripts/UI/main_menu.gd`: inicia o fade e transfere a cortina para a batalha antes de remover o menu.
- `Scripts/main.gd`: decide a apresentação, escolhe a unidade e controla a liberação da interface e do arraste.
- `Scripts/Camera/camera.gd`: anima a câmera e devolve o controle ao sistema de órbita.

Erros ao restaurar uma campanha retiram a cortina para permitir o acesso ao menu de recuperação. A transição pertence à cena de batalha e é removida ao terminar.

Implementação ainda não executada no Godot.
