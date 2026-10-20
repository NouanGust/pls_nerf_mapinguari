# Tabuleiro com banco de reserva integrado — plano de produção

Estado em 20/10/2026: levantamento, plano e script de autoria nativa concluídos.
A conexão Blockbench foi restabelecida após a primeira etapa. O arquivo
`tools/art/build_board_bench.js` cria meshes e atlas no editor por APIs nativas,
em um projeto Generic Model vazio, com transação Undo. Não escreve `.bbmodel`
manualmente nem modifica o projeto Anhangá aberto. A execução, inspeção visual
e exportação ficam com o agente principal para serializar o uso do editor.

Validação isolada do script: 159 meshes; 1.688 triângulos no conjunto completo;
568 na estrutura com bancada; 1.120 nas casas de prévia; um atlas PNG 512×512.
Foram verificadas ausência de faces degeneradas e coordenadas UV dentro do
atlas. Essa verificação usa um ambiente de teste das operações geométricas,
não substitui validação e renderização no Blockbench.

## Intenção visual e escopo

Peça low poly para a versão alpha de Folchess: base de madeira escura e pedra,
com bancada baixa de nove reservas incorporada ao lado do jogador. Entende-se
“banco” como a reserva de peças do autobattler, conforme o projeto atual.
O conjunto deve parecer uma mesa ritual da mata: blocos largos, bordas gastas,
poucos detalhes de raiz nos cantos e discreta marcação dos nove lugares.
Madeira e pedra devem ficar menos contrastadas que as unidades e os realces de
combate. Não usar símbolos culturais específicos inventados.

O asset planejado é uma estrutura visual estática. As 56 casas interativas
existentes continuam sendo geradas pelo jogo, preservando os realces individuais.
Não duplicar essas casas no export de runtime. É possível produzir uma prévia
do conjunto completo posteriormente, mantendo os hexágonos de demonstração em
grupo separado e excluído do export da estrutura.

## Fonte de verdade no jogo

- `Scenes/Main/main.tscn` instancia `Scenes/Board/board.tscn`.
- `Scenes/Board/board.tscn` usa `Scripts/Board/board.gd`, classe `Board3D`, sem
  sobrescrever as dimensões do script.
- `Scripts/main.gd` mantém `bench_units`, com `max_bench_size = 9`; em
  `add_unit_to_bench`, esconde a unidade e a posiciona em
  `Vector3(-20 - bench_units.size(), -100, 0)`.
- `Scripts/UI/bench_ui.gd` exibe nove slots na interface.
- `Scripts/Board/board_drag_handler.gd` usa a região da interface do banco para
  receber peças; o raycast do tabuleiro usa máscara `2`.
- `bench.gd`, `bench.tscn` e `Scripts/Board/board_manager.gd` não definem a
  geometria ativa da cena principal. O `bench.gd` legado usa multiplicação em
  `start_x * (index * slot_spacing)` e não deve fornecer os centros do novo asset.

Não existe hoje um banco 3D visível ou um contrato de posição 3D das reservas.
As medidas da bancada abaixo são **propostas de arte**, não valores existentes
no runtime. Exibir e manipular reservas nela exigirá uma etapa de integração.

## Medidas verificadas

Todas as medidas abaixo usam unidades Godot. O projeto não declara uma escala
física; adota-se, apenas para autoria, 1 unidade Godot = 1 metro nominal.
O centro da grade é a origem local `(0, 0, 0)`, com Y para cima, X entre colunas
e Z entre linhas. O jogador ocupa o lado +Z.

| Elemento ativo | Valor |
| --- | --- |
| Grade | 7 colunas × 8 linhas = 56 casas |
| Linhas do jogador | Índices 4, 5, 6, 7, total de 28 casas |
| `cell_size` / raio externo do hexágono | 2,0 / 1,0 |
| `cell_spacing` | 0,12 |
| Passo horizontal | `sqrt(3) + 0.12` = 1,8520508076 |
| Passo vertical | `1.5 + 0.12` = 1,62 |
| Deslocamento X nas linhas ímpares | 0,9260254038 |
| Extensão retornada pelo script | X 14,0383302492 × Z 13,34 |
| Piso e colisão de seleção | X 14,8383302492 × Z 14,14 |
| Limites do piso | X ±7,4191651246; Z ±7,07 |
| `board_height`, origem das unidades | Y 0 |
| Contorno de cada casa | Raio 1,0; altura 0,055; centro Y 0,035 |
| Topo do contorno | Y 0,0625 |
| Superfície interna | Raio 0,91; altura 0,035; centro Y 0,075 |
| Topo da superfície interna | Y 0,0925 |
| Colisão `BoardCollision` | Caixa 14,8383302492 × 0,1 × 14,14, centro Y 0, camada 2 |
| `NavigationGeometry` | Caixa 14,0383302492 × 0,05 × 13,34, centro Y -0,1, camada 4, máscara 0 |

“Extensão retornada” é o envelope conservador calculado pelo script; não é uma
medição do contorno exato dos polígonos. Para reproduzir o alinhamento, usar:

```text
x(col,row) = -6.0191651246 + col * 1.8520508076
             + (0.9260254038 se row for ímpar; senão 0)
z(row)     = -5.67 + row * 1.62
y         = 0
```

Centros de conferência: casa `(0,0)` = `(-6.0191651246,0,-5.67)` e casa
`(6,7)` = `(6.0191651246,0,5.67)`. A camada visual atual tem topo acima da
origem das unidades; o novo asset não deve elevar silenciosamente esse apoio.

## Proposta dimensional da estrutura

| Parte proposta | Medidas e posicionamento |
| --- | --- |
| Base principal | X 14,8383302492 × Z 14,14; Y de -0,60 a -0,01 |
| Moldura periférica | Dentro do envelope do piso; Y 0,035, pequenos acentos até 0,057, sem invadir as casas |
| Bancada integrada | X 14,8383302492 × Z 2,30; centro Z 8,22; limites Z 7,07 a 9,37 |
| Corpo da bancada | Y de -0,60 a -0,01, continuidade com a base |
| Nove apoios de reserva | Centros X = `(i - 4) * 1.55`, Z 8,22, i = 0…8 |
| Marcações dos apoios | Diâmetro 1,24; desenho de baixa saliência, topo máximo Y 0 |
| Envelope da estrutura | X ±7,4191651246; Z -7,07 a 9,37; Y -0,60 a 0,057 |
| Envelope com casas de prévia | Mesmos X/Z; Y -0,60 a 0,0925 |
| Pivot | Origem da grade existente, sem recentrar pelo envelope completo |

O espaçamento proposto dá centros X entre -6,20 e +6,20. As reservas poderão
precisar de escala de apresentação própria quando houver integração 3D;
conferir chifres, caudas e asas de unidades largas antes de fixar essa escala.
Na primeira versão, as marcações são decorativas e o banco funcional continua
na interface.

Usar meshes facetados para a base e extremidades chanfradas; guardar detalhes
de ranhura, musgo e desgaste para a textura. Raízes e pedras de canto ficam
abaixo ou fora da superfície das casas. Não acrescentar árvores altas,
encosto, postes ou folhagem sobre o campo.

## Contrato de autoria e orçamento proposto

```text
Destino:              Godot 4.6, alpha desktop, uma instância por arena.
Formato de autoria:   Generic Model / free, após confirmar capacidades.
Preferência aplicada: Low poly, conforme pedido do usuário.
Escala de autoria:    16 unidades Blockbench = 1 unidade Godot.
Conversão:            Aplicar escala 0,0625 exatamente uma vez; validar export.
Shading:              Estilizado facetado; albedo com desgaste discreto.
Materiais:            1 opaco na estrutura; sem transparência ou normal map.
Orçamento:            Até 1.800 triângulos incluindo a grade de prévia.
Textura:              Atlas PNG 512×512, quadrado, com regiões reutilizadas.
Densidade proposta:   16 px por unidade Godot nas superfícies com padrão.
UV:                   Ilhas proporcionais; sobreposição só em peças repetidas.
Detalhes:             Madeira, pedra, musgo e marcas pintados no albedo.
Animação:             Nenhuma; estrutura estática.
Colisão do asset:     Nenhuma automática; preservar os volumes atuais.
```

O atlas pode dedicar as maiores regiões à madeira/pedra do campo, reutilizar
UVs da bancada e espelhar peças simétricas. Verificar empacotamento antes de
adicionar detalhes; superfícies planas sem padrão podem usar swatches sólidos,
com essa exceção registrada. Não esticar a mesma região de textura sobre faces
de proporções diferentes.

Paleta proposta: madeira `#463B34`, veio `#292722`, pedra `#68665B`, musgo
`#454D37`, desgaste `#94836C`. As cores de gameplay existentes pertencem às
casas: jogador `#4B777B`, inimigo `#74614F`, borda `#251F1C`.

Hierarquia proposta:

```text
board_bench_root
  runtime_shell
    board_base
    board_frame
    bench_base
    reserve_marks_9
      reserve_socket_00 … reserve_socket_08
      reserve_inlay_00 … reserve_inlay_08
    corner_stone_and_roots
  preview_hex_cells_REMOVE_FOR_RUNTIME
```

Um único subagente será dono do arquivo de autoria, utilizando as revisões
retornadas pelo servidor. Os caminhos futuros sugeridos são
`Assets/Models/Environment/board_bench/board_bench.bbmodel`,
`board_bench_albedo.png` e, se houver exportador compatível, `board_bench.glb`.
Esses arquivos ainda não existem como entregas deste trabalho.

## Sequência de produção ao restabelecer Blockbench

1. Confirmar `bbmodel_*` ou o servidor desktop e suas capacidades. No headless,
   usar `expected_revision` em todas as edições. Não editar o mesmo arquivo
   simultaneamente no desktop e no servidor headless.
2. Criar o arquivo `free`, montar base e bancada nas medidas acima e validar
   escala, pivot, nove apoios e silhueta antes de detalhar.
3. Usar `bbmodel_validate` e uma contact sheet de topo, frente, lateral e
   três quartos; corrigir peças flutuantes, furos visíveis e proporções.
4. Aplicar checker UV para conferir densidade e distorção; finalizar o atlas,
   inspecioná-lo e renderizar o modelo texturizado nas mesmas vistas.
5. Salvar `.bbmodel` editável. Descobrir o codec real de exportação; o headless
   padrão não garante export glTF/GLB. Se GLB não estiver disponível, registrar
   a limitação e usar um exportador suportado, sem renomear outro formato.
6. Conferir no Godot dimensões, orientação e escala de importação. Posicionar o
   visual como filho separado do tabuleiro, evitando que `generate_board()`
   remova o asset junto de `GeneratedBoard`.
7. Preservar as casas e seus materiais individuais. Se a base visual substituir
   o piso antigo, desativar apenas a malha de piso correspondente; manter
   `BoardCollision` e `NavigationGeometry`. Não gerar colisões do banco na
   camada 2: fora do campo, elas interceptariam o raycast de seleção.

## Integração e critérios de aceitação pendentes

A câmera atual calcula o enquadramento com a extensão do campo mais 0,8, sem a
bancada adicional. Seu ângulo inicial é 55°, yaw 0°, com jogador embaixo, e
permite órbita e zoom. A extensão +Z até 9,37 precisa entrar no cálculo de
enquadramento ou receber tratamento explícito antes da entrega integrada.
Também verificar o painel de reservas e a loja: ambos ocupam espaço inferior
da tela. Não considerar a bancada visível em jogo apenas porque apareceu
corretamente num render isolado.

- Comparar o alinhamento das quatro casas extremas e de duas linhas alternadas.
- Conferir os nove apoios e o pivot sem deslocamento após importação.
- Inspecionar câmera padrão, órbita completa e elevações de 20° e 80°.
- Verificar em 1280×720 e 1600×900, com HUD aberto e oculto.
- Arrastar para casas nas extremidades; confirmar realces, seleção e retorno
  ao banco pela interface.
- Confirmar que a navegação e as colisões permanecem as mesmas.
- Registrar contagem real de triângulos, materiais e tamanho de textura.
- Entregar `.bbmodel`, textura, export suportado e contact sheet revisada.

As verificações de importação e renders ainda dependem da execução do script
pelo agente principal. Os dados dimensionais foram conferidos por leitura do
código e recálculo das fórmulas; o gerador foi verificado sem alterar o editor
compartilhado. Não há ainda integração funcional de reservas 3D no runtime.
