# Guia de montagem do painel de sinergias no Godot

O layout, as texturas, as cores e as posições do painel ficam na cena e podem ser ajustados pelo editor. O script `Scripts/UI/game_ui.gd` só liga o botão, duplica um dos modelos de linha e preenche os nomes, a contagem, o progresso e o tooltip.

## Árvore de nós

Adicione estes nós como filhos de `GameUi/Control`:

```text
Control
├── SynergyToggleButton (Button)
└── SynergyPanel (PanelContainer)
    └── ScrollContainer
        └── SynergyList (VBoxContainer)
            ├── SynergyRowTemplateActive (PanelContainer)
            └── SynergyRowTemplateInactive (PanelContainer)
```

Monte cada modelo de linha com esta estrutura e estes nomes. Os dois modelos precisam ter a mesma árvore interna:

```text
SynergyRowTemplateActive ou SynergyRowTemplateInactive (PanelContainer)
└── Row (HBoxContainer)
    ├── Icon (TextureRect)
    └── Content (VBoxContainer)
        ├── Header (HBoxContainer)
        │   ├── TagLabel (Label)
        │   └── CountLabel (Label)
        └── Progress (ProgressBar)
```

Os caminhos `TagLabel`, `CountLabel` e `Progress` são usados pelo script para preencher os dados. Mantenha os nomes e a hierarquia exatamente como acima. O painel pode ter filhos decorativos adicionais, desde que não alterem esses caminhos. Deixe os dois modelos ocultos na cena; o script duplica o modelo ativo ou inativo adequado e mostra a cópia.

## Posições e tamanhos sugeridos

Use o `Control` existente como área de referência e deixe os nós ancorados no canto superior esquerdo:

| Nó | Posição | Tamanho sugerido |
| --- | --- | --- |
| `SynergyToggleButton` | `(18, 82)` | `142 × 34` |
| `SynergyPanel` | `(18, 122)` | `250 × 420` |
| `ScrollContainer` | preencher o painel, com margem interna | cerca de `226 × 400` |
| Cada modelo de linha | largura preenchida | mínimo `224 × 42` |
| `Icon` | automático no HBox | `24 × 24` |
| `Progress` | preencher a largura | altura `5` |

Deixe `SynergyPanel` visível inicialmente. O botão já alterna a visibilidade do painel. O painel usa rolagem vertical para listas compridas.

## Ícone placeholder

No `Icon`, use uma `AtlasTexture` baseada em `res://Assets/UI/GUI_4x.png`. Para o placeholder usado como referência, configure a região do atlas como `x=256, y=256, largura=16, altura=16`. Deixe `Expand Mode` em **Ignore Size**, `Stretch Mode` em **Keep Aspect Centered** e o filtro de textura em **Nearest**.

Você pode substituir essa região por outro ícone do mesmo atlas sem alterar o script.

## Aparência sugerida

Configure os dois modelos separadamente no Inspector para que o script possa escolher o visual conforme o estado:

| Propriedade | Ativa | Inativa |
| --- | --- | --- |
| Fundo da linha | `#244641` | `#252D35` |
| Borda | `#66B8A3` | `#59636A` |
| Texto do nome | `#F0D58B` | `#C0C8C8` |
| Preenchimento da barra | `#64D0AD` | `#7D9A9B` |
| Fundo da barra | `#172126` | `#172126` |

Nos dois modelos, use uma borda de 1 px, cantos arredondados discretos e margens internas de aproximadamente 6 px na horizontal e 4 px na vertical. No `Progress`, desative a porcentagem e configure os estilos de fundo e preenchimento. O script ajusta `Max Value` e `Value` conforme as unidades no campo.

Para a linha, use `Mouse Filter: Stop`; nos nós internos (`Row`, `Icon`, `Content`, `Header`, labels e barra), use `Mouse Filter: Ignore`. Assim o tooltip da linha aparece ao passar o cursor sobre qualquer parte dela.

## Cards e inspeção de unidade

Os cards já têm `VBox/TraitsContainer/OriginLabel` e `ClassLabel`; o script preenche os nomes de todas as etiquetas da unidade. Para acomodar os nomes longos como na interface anterior, ajuste manualmente o card para um mínimo de `108 × 174` e o `IconRect` para `92 × 46`.

O painel de inspeção na cena já contém `Origins_label`, `Classes_label` e `Affinities_label` sob `Control/RightBar/VBoxContainer`. O clique direito preenche esses campos. Ajuste tamanho, ordem, fonte e estilo pelo Inspector sem alterar esses nomes.

## Botão e comportamento

Nomeie o botão `SynergyToggleButton`. O script atualiza seu texto para `Sinergias · N`, em que `N` é a quantidade de sinergias ativas, e conecta o clique para abrir ou fechar o painel.

O painel recebe somente etiquetas presentes nas unidades vivas do jogador que estão no tabuleiro. Etiquetas ainda inativas também aparecem quando há pelo menos uma unidade correspondente; por exemplo, `Origem · Amazônico 1/2`. O tooltip de cada linha é preenchido com o efeito/status e a relação de unidades do elenco que possuem aquela etiqueta.

## Conferência

- Os nomes e caminhos dos nós coincidem com a árvore deste guia.
- Os dois modelos de linha estão ocultos na cena (`Visible` desmarcado), mas seus filhos estão visíveis.
- `SynergyPanel` está visível ao iniciar; o script controla sua abertura pelo botão.
- `SynergyList` é filho direto do `ScrollContainer` e aceita expansão horizontal.
- Ambos os modelos contêm `TagLabel`, `CountLabel` e `Progress` nos caminhos indicados.
