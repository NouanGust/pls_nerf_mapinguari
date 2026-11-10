# AGENTS.md — projeto de arte 3D (autochess folclórico)

## Contexto
Este workspace contém a produção de arte 3D do jogo: descrições das lendas,
referências, arquivos Blender e exports .glb para a Godot 4.x.

## Fonte de verdade
O design de cada unidade vem de `art/lore/<unidade>.md` — descrição em Markdown.
Não existe concept art como fonte canônica. A especificação vigente está em
`docs/AGENTE_MODELAGEM_3D.md`; leia-a inteira antes de modelar, riggar ou animar.
Se este arquivo e a especificação divergirem, vale a especificação.

## Invariantes (nunca viole)
- Orçamento por personagem: 6k–9k triângulos (teto 15k), 1 material,
  atlas 1024² (teto 2048²), 25–45 bones, no máximo 4 influências por vértice.
- Seis clipes por unidade, nomes exatos: Idle, Attack, Stunned, Channel, Death, Ability.
- Root motion sempre desligado.
- Antes de modelar: `DESIGN_BRIEF.md` + prancha de interpretação aprovados.
- Entregar sempre `.blend` + `.glb` + `REPORT.md` na pasta da unidade.
- Sem `.glb` reimportado e validado na Godot, a tarefa não está concluída.

## Canônico vs. autoral
- O que está escrito na descrição é canônico: siga sem alterar.
- Deduções a partir do texto são "derivadas": registre o raciocínio.
- Invenções para preencher lacunas são "autorais": liste e peça aprovação.
- Pesquisa e vídeos enriquecem detalhe; nunca sobrepõem o texto.

## Limites de escrita
- Escreva apenas em `art/`, `models/` e `docs/units/`.
- Não edite `godot/` sem pedido explícito.
- Não sobrescreva arquivos de outras unidades.

## Ferramentas
- Blender sempre headless: `blender -b <arquivo>.blend --python <script>.py`
- Pesquisa: use o navegador; cite fontes com link e data no `REPORT.md`.
- Vídeo: extraia quadros com ffmpeg em vez de afirmar que "assistiu".

## Idioma
Responda em português do Brasil. Nomes técnicos e de arquivos em inglês.
