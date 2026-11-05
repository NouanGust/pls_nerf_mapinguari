# Agente Blender — Arena de Autochess no Pantanal

## 1. Missão

Crie no Blender uma cena 3D de ambiente para um jogo de autochess de horror folclórico brasileiro, ambientada em uma paisagem pantaneira parcialmente alagada ao entardecer.

Execute a construção da cena, não apenas descreva como ela poderia ser feita.

O resultado deve apresentar:

- Um tabuleiro hexagonal completo, funcional e legível.
- Uma faixa frontal de reserva de unidades.
- Terreno contínuo integrando o campo às margens.
- Canais de água entre manchas irregulares de vegetação.
- Árvores espaçadas e grupos de vegetação ao fundo.
- Uma cerca rural deteriorada.
- Uma canoa antiga e vazia, parcialmente encalhada.
- Iluminação de entardecer com reflexos quentes e sombras frias.
- Horror ambiental sutil, associado à água e às passagens entre margens.
- Ausência de personagens, unidades e criaturas.

O campo deve ocupar um trecho baixo de terra firme.

Não crie uma plataforma flutuante, uma ilha perfeitamente retangular ou uma arena cercada por um fosso.

## 2. Prioridades

Resolva os objetivos nesta ordem:

1. Tabuleiro completo e legível.
2. Reserva frontal totalmente visível.
3. Integração natural entre terra, água e vegetação.
4. Identidade de paisagem pantaneira aberta.
5. Iluminação de entardecer.
6. Reflexos controlados.
7. Horror ambiental sutil.
8. Detalhes decorativos.

Se houver conflito entre reflexos e leitura do jogo, preserve a leitura.

Se houver conflito entre água e funcionalidade do campo, mantenha a água fora da área jogável e ajuste as margens.

## 3. Modo de execução

1. Inspecione a versão do Blender e as ferramentas disponíveis.
2. Verifique se existe uma cena antes de modificar objetos.
3. Não apague conteúdo preexistente sem autorização.
4. Trabalhe em uma coleção própria para este ambiente.
5. Use operações nativas do Blender e, quando disponível, automação por Python com `bpy`.
6. Não dependa de complementos pagos ou downloads externos.
7. Utilize referências fornecidas pelo usuário quando estiverem acessíveis.
8. Para pequenas decisões artísticas, use os parâmetros padrão deste documento.
9. Registre limitações e decisões de implementação.
10. Não afirme ter salvo, renderizado ou validado algo que não foi executado.

Se não for possível executar o Blender, informe a limitação.

Não apresente uma descrição como se fosse uma cena concluída.

## 4. Referências e interpretação

Use as fotografias do Pantanal fornecidas pelo usuário para orientar:

- Lâminas de água entre manchas de vegetação.
- Margens baixas de capim.
- Canais sinuosos e conectados.
- Árvores espaçadas.
- Plantas aquáticas agrupadas.
- Reflexos de céu, troncos e vegetação.
- Luz quente de entardecer.
- Contraste entre áreas iluminadas e sombras frias.

Não copie literalmente o enquadramento panorâmico das fotografias.

A cena deve continuar sendo um ambiente de jogo visto por uma câmera elevada de três quartos.

Use a referência do protótipo exclusivamente para:

- Campo hexagonal central.
- Reserva na frente.
- Cenário nas laterais e no fundo.

Não copie:

- Árvores geométricas.
- Muralhas.
- Tochas.
- Plataforma elevada.
- Cores ou acabamento plástico.

Se as imagens não estiverem acessíveis, siga a descrição deste documento e registre a ausência.

## 5. Parâmetros configuráveis

Centralize os parâmetros de geração em uma configuração única.

| Parâmetro | Valor inicial |
|---|---|
| Nome da cena | `Pantanal_Autochess` |
| Unidade de trabalho | Metro |
| Eixo vertical | Z |
| Frente do campo | Y negativo |
| Fundo do campo | Y positivo |
| Centro do campo | Próximo da origem |
| Colunas de hexágonos | 8 |
| Fileiras de hexágonos | 8 |
| Raio do hexágono | 0,65 m |
| Orientação dos hexágonos | Ponta para cima |
| Posições de reserva | 9 |
| Semente aleatória | 42 |
| Proporção da imagem | 16:9 |
| Resolução final | 1920 × 1080 |
| Ocupação horizontal do conjunto jogável | 55% a 65% |
| Horário visual | Final do pôr do sol |
| Direção visual do sol | Baixo à esquerda, atrás do campo |

Esses valores são padrões de implementação, não medidas obrigatórias das referências.

Se houver um tabuleiro existente ou dimensões fornecidas pelo usuário, preserve essas dimensões.

## 6. Organização da cena

Crie a coleção principal:

`PANTANAL_ENV`

Organize os objetos em:

- `00_CONTROLS`
- `01_TERRAIN`
- `02_BOARD`
- `03_RESERVE`
- `04_WATER`
- `05_BANK_VEGETATION`
- `06_AQUATIC_PLANTS`
- `07_TREES`
- `08_FENCE_AND_CANOE`
- `09_HORROR_DETAILS`
- `10_LIGHTS`
- `11_CAMERAS`

Use nomes claros, como:

- `Terrain_Main`
- `Board_Hex_00_00`
- `Reserve_Slot_00`
- `Water_MainChannel`
- `Water_SidePool_A`
- `Grass_Bank_Variant_A`
- `Aquatic_Cluster_A`
- `Tree_Variant_A`
- `Fence_Post_A`
- `Canoe_Abandoned`
- `Camera_Game`
- `Light_Sunset_Key`

Mantenha a cena editável.

Não una todo o ambiente em uma única malha.

## 7. Conceito espacial — terra firme entre águas

Construa o campo sobre um trecho baixo e relativamente plano de terra firme.

Esse terreno deve se conectar naturalmente:

- À margem frontal.
- A pelo menos uma lateral.
- A pequenas extensões de solo entre a vegetação.

A água se aproxima de algumas bordas e se afasta de outras.

Não crie água com distância uniforme ao redor do campo.

Evite:

- Ilha retangular.
- Fosso.
- Plataforma elevada.
- Arena cercada por passarelas.
- Cais ocupando todo o perímetro.
- Um único grande plano de água sem margens ou profundidade.

Use curvas assimétricas para integrar canais, bancos de lama e manchas de capim.

## 8. Terreno e margens

Crie um terreno que se estenda além do enquadramento.

Integre:

- Campo.
- Reserva.
- Margens.
- Bancos de sedimento.
- Canais rasos.
- Vegetação externa.

### Área jogável

- Relativamente plana.
- Terra compactada.
- Textura simples.
- Sem poças extensas.
- Sem lama brilhante.
- Sem plantas altas.
- Sem raízes ou pedras volumosas.

### Áreas externas

Adicione:

- Pequenas depressões.
- Margens suavemente inclinadas.
- Sedimento acumulado.
- Capim parcialmente próximo da água.
- Marcas de umidade.
- Pequenas irregularidades no terreno.

Não use barrancos altos ou penhascos.

A transição entre terra e água deve parecer baixa e gradual.

### Relação de altura

Defina um nível de água comum para os canais conectados.

Mantenha o campo e a reserva acima desse nível.

Evite superfícies de terra e água quase coplanares, que causem cintilação ou interseções visíveis.

Ajuste a diferença de altura à escala da cena, sem transformar o terreno jogável em um pedestal.

## 9. Grade hexagonal

Crie por padrão 8 colunas e 8 fileiras de hexágonos regulares.

Use uma única convenção geométrica.

Para hexágonos com ponta para cima e raio `R`, use:

- Espaçamento horizontal entre centros: `sqrt(3) * R`.
- Espaçamento vertical entre fileiras: `1.5 * R`.
- Deslocamento horizontal de meia célula em fileiras alternadas.

Centralize a grade após calcular seus limites.

O campo deve ter contorno geral aproximadamente retangular, preservando a borda natural dos hexágonos.

Não corte as casas externas para forçar um retângulo perfeito.

### Aparência das casas

As casas devem parecer marcadas na terra, não blocos empilhados.

Use:

- Sulcos rasos.
- Diferenças discretas de compactação.
- Pequenas variações de marrom e ocre.
- Bordas suavemente desgastadas.

Faixa inicial sugerida para os sulcos:

- Largura: 0,015 a 0,03 m.
- Profundidade visual: 0,005 a 0,015 m.

Ajuste após observar o render da câmera final.

Os sulcos podem parecer um pouco mais úmidos que a superfície.

Não os transforme em canais preenchidos com água.

Não use:

- Emissão.
- Contornos luminosos.
- Moldura de pedra.
- Mosaico ornamental.
- Elevação individual evidente.
- Reflexos fortes sobre as casas.

Evite superfícies coplanares sobrepostas.

Preserve identificadores individuais das casas por nomes ou metadados.

## 10. Reserva frontal

Crie uma fileira com 9 posições diante do campo, no lado Y negativo.

Cada posição deve:

- Estar vazia.
- Ter dimensão uniforme.
- Ser identificável na câmera.
- Estar integrada ao mesmo terreno.
- Usar sulcos ou diferenças discretas de material.

Centralize a fileira em relação ao campo.

Mantenha a reserva acima do nível da água.

Não coloque plantas aquáticas, lama profunda ou poças sobre as posições.

Não crie degraus, pedestais ou uma plataforma frontal.

## 11. Máscaras de exclusão e oclusão

Defina regiões de exclusão para:

1. Interior das casas.
2. Faixa de reserva.
3. Margem de segurança do conjunto jogável.
4. Corredor visual entre a câmera e a borda frontal.

Use margem inicial de aproximadamente 0,5 m, ajustável conforme a escala.

A exclusão deve considerar o volume final dos objetos.

Um arbusto fora da máscara não pode projetar folhas sobre as casas.

Crie também uma máscara que impeça a água de ocupar o campo ou a reserva.

Após espalhar a vegetação, valide sua projeção na câmera.

## 12. Água e canais

Crie um canal mais amplo ao fundo e trechos rasos nas laterais.

Conecte as áreas de água de maneira irregular.

Não faça todos os canais convergirem simetricamente para o campo.

### Superfície

Use:

- Ondulações discretas.
- Pequenas diferenças de rugosidade.
- Reflexos fragmentados.
- Variação visual associada à profundidade e ao fundo.

A água deve combinar:

- Marrom.
- Cinza-esverdeado.
- Cobre nos reflexos.
- Tons frios nas áreas em sombra.

Não use azul saturado como cor principal.

Não transforme toda a água em um espelho perfeito.

### Geometria e material

Use uma superfície com topologia suficiente para os detalhes realmente necessários.

Priorize materiais e pequenas deformações em vez de simulações complexas.

Não execute uma simulação de fluido se uma superfície estática controlada resolver a cena.

Modele ou sugira o fundo nos trechos rasos visíveis.

Evite transparência uniforme que faça toda a água parecer igualmente rasa.

## 13. Vegetação das margens

Crie variantes de:

- Capim curto.
- Touceiras médias.
- Capim mais alto em grupos externos.
- Pequenos arbustos.
- Plantas emergentes próximas da água.

Distribua em manchas assimétricas.

Use:

- Vegetação mais baixa perto do campo.
- Touceiras maiores nas margens externas.
- Pequenas interrupções de solo visível.
- Faixas parcialmente submersas em pontos selecionados.

Não distribua capim com a mesma altura e densidade em toda a cena.

Não transforme as margens em um muro de vegetação.

Use instâncias ou duplicatas vinculadas quando adequado.

## 14. Plantas aquáticas

Crie pequenos agrupamentos de:

- Folhas flutuantes.
- Hastes emergentes.
- Vegetação baixa parcialmente submersa.

Distribua em manchas com áreas de água aberta entre elas.

Não cubra toda a superfície com o mesmo padrão.

Varie:

- Tamanho.
- Rotação.
- Densidade.
- Distância entre grupos.

Evite sobreposição coplanar com a superfície da água.

As plantas aquáticas devem ajudar a fragmentar os reflexos sem criar ruído excessivo.

Não as coloque sobre o tabuleiro ou a reserva.

## 15. Árvores e profundidade da paisagem

Crie pelo menos 4 variantes de árvores, com diferenças em:

- Altura.
- Inclinação.
- Espessura do tronco.
- Bifurcações.
- Volume da copa.

Distribua:

- Algumas árvores isoladas nas laterais.
- Pequenos grupos mais distantes.
- Massas de vegetação ao fundo.
- Intervalos de água e capim entre esses grupos.

Algumas árvores podem ficar próximas da água.

Inclua apenas um tronco morto ou quebrado em uma margem externa.

Ele deve parecer natural, não uma escultura monstruosa.

Não transforme o cenário em:

- Floresta tropical fechada.
- Manguezal de raízes monumentais.
- Pântano gótico de árvores mortas.
- Círculo simétrico de árvores.

Nenhuma árvore pode esconder a borda frontal.

## 16. Cerca deteriorada

Crie um pequeno trecho de cerca rural em uma lateral externa.

Inclua:

- Poucos mourões.
- Inclinações variadas.
- Madeira desgastada.
- Bases escurecidas.
- Marcas de antigos níveis de água.
- Segmentos discretos de arame.

Parte da cerca pode desaparecer no capim.

Não transforme a cerca em uma barreira completa ao redor do campo.

Não inclua caveiras ou adereços ritualísticos.

## 17. Canoa abandonada

Crie uma canoa antiga e vazia, parcialmente encalhada próximo da cerca.

A posição deve:

- Ficar fora da área jogável.
- Não esconder hexágonos.
- Permanecer secundária.
- Permitir reconhecer sua silhueta na câmera.

Modele:

- Casco estreito.
- Interior visível.
- Bordas desgastadas.
- Madeira escurecida.
- Pequeno acúmulo de folhas ou sedimento.

A canoa não deve parecer um bloco sólido ou uma caixa.

Não inclua ocupantes, carga chamativa, lanternas ou ornamentação.

Se houver um remo, mantenha-o discreto e apoiado de maneira plausível.

## 18. Horror ambiental

Implemente três anomalias discretas, todas fora do campo.

### A. Reflexo com um ramo a mais

Escolha uma árvore lateral cujo reflexo seja parcialmente visível.

No reflexo, faça aparecer um pequeno ramo que não existe na silhueta observada acima da água.

A diferença deve ser sutil.

Não transforme o reflexo em rosto, corpo ou criatura.

#### Implementação

Prefira uma solução controlada e localizada, compatível com o motor de renderização escolhido.

Possibilidades:

- Elemento adicional restrito à contribuição de reflexão, se houver controle adequado.
- Composição localizada com máscara.
- Detalhe de material integrado ao reflexo e quebrado pelas ondulações.

Não coloque um galho visível flutuando sobre a água como substituto.

Não deixe o efeito parecer uma imagem colada.

Se não for possível implementar a anomalia com qualidade, registre a limitação e use uma distorção localizada suspeita, sem alegar que produziu um reflexo fisicamente incompatível.

### B. Passagem submersa junto à canoa

Crie uma faixa curta de ondulações próximas da canoa vazia.

As ondulações sugerem deslocamento recente sob a superfície.

Não mostre corpo, olhos ou uma sombra identificável.

Use deformação ou material localizado, sem uma sequência uniforme de círculos decorativos.

### C. Capim amassado que reaparece

Crie uma passagem estreita de capim inclinado que chega à margem e desaparece na água.

Em outro ponto, faça surgir um trecho semelhante, com continuidade espacial suspeita.

O efeito deve sugerir uma trajetória difícil de explicar.

Não ilumine esses indícios com fontes próprias.

Eles devem ser descobertos depois que o observador reconhecer o campo e a paisagem.

Esses elementos são recursos ficcionais de horror ambiental, não uma representação literal de uma tradição específica.

## 19. Fauna e silêncio visual

Não inclua animais próximos ou grandes o suficiente para serem confundidos com unidades.

Não copie grupos de capivaras ou aves para o primeiro plano.

Nesta cena, preserve a ausência de fauna visível.

O silêncio visual deve concentrar a atenção em:

- Tabuleiro.
- Margens.
- Canoa.
- Reflexos.
- Vestígios de passagem.

Não use olhos de animais nas sombras para criar horror.

## 20. Materiais

Estilo:

- 3D estilizado.
- Acabamento pictórico sombrio.
- Volumes claros.
- Materiais reconhecíveis.
- Umidade localizada.

Paleta:

- Verde-oliva.
- Verde profundo.
- Verde amarelado discreto nas áreas iluminadas.
- Marrom úmido.
- Ocre apagado.
- Madeira acinzentada.
- Cobre.
- Âmbar.
- Rosa queimado.
- Cinza frio.

Use materiais procedurais quando não houver texturas locais.

Mantenha escala coerente das texturas.

Evite:

- Mesmo ruído em todos os materiais.
- Bump exagerado.
- Terra envernizada.
- Água plástica.
- Folhas inteiramente brilhantes.
- Emissão em elementos naturais.
- Filtro laranja cobrindo toda a cena.

## 21. Iluminação de entardecer

O sol está muito baixo, fora do enquadramento, à esquerda e atrás do campo.

Toda a iluminação direcional deve respeitar essa origem.

Não é necessário modelar um disco solar.

Construa a iluminação em quatro camadas.

### Camada 1 — Luz direta rasante

Use tonalidade quente moderada:

- Âmbar.
- Cobre.
- Laranja queimado pouco saturado.

A luz deve atingir seletivamente:

- Pontas do capim.
- Bordas de folhas.
- Faces laterais de troncos.
- Partes da canoa.
- Algumas margens.

Não ilumine toda a paisagem com a mesma intensidade.

Não crie uma faixa branca sobre o tabuleiro.

### Camada 2 — Reflexos quentes

Concentre os reflexos mais intensos em trechos externos da água.

Prefira o fundo e uma das laterais.

Os reflexos devem:

- Ser fragmentados.
- Apresentar interrupções.
- Variar com as ondulações.
- Ser parcialmente ocultos por vegetação.

Não crie um caminho brilhante atravessando o campo ou a reserva.

Ajuste posição da luz, câmera, rugosidade da água e distribuição dos canais antes de recorrer à composição.

### Camada 3 — Preenchimento frio

Use preenchimento suave em cinza levemente azulado.

Ele deve manter visíveis:

- Todas as casas.
- Sulcos.
- Reserva.
- Faces sombreadas das árvores.
- Textura da canoa.

O campo permanece em valores médios.

Se precisar de luz auxiliar, mantenha contribuição ampla e discreta.

Não faça a área jogável parecer iluminada por um holofote.

Preserve as cores próprias dos materiais.

### Camada 4 — Profundidade atmosférica

Reduza o contraste das árvores e canais distantes.

Uma umidade muito tênue pode suavizar o fundo.

Não crie uma parede de névoa.

Não coloque névoa sobre o tabuleiro.

O primeiro plano deve conservar detalhes, sem virar uma faixa preta.

## 22. Sombras e controle de reflexos

As sombras sobre a área jogável devem ser:

- Suaves.
- Esparsas.
- Pouco contrastadas.
- Diferentes visualmente dos sulcos.

Não projete um emaranhado de galhos sobre as casas.

Não deixe uma grande árvore escurecer toda a reserva.

Os valores mais intensos dos reflexos devem permanecer fora do conjunto jogável.

Nenhuma mancha de luz pode fazer os limites de uma casa desaparecerem.

Não escureça a cena inteira para criar horror.

## 23. Câmera

Crie `Camera_Game`.

Use perspectiva elevada de três quartos.

Ponto de partida:

- Câmera no lado Y negativo.
- Direcionada ao centro do conjunto jogável.
- Inclinação aproximada de 50° a 60° abaixo da horizontal.
- Distância focal inicial entre 45 e 60 mm.

Ajuste conforme os limites reais da cena.

Critérios:

- Campo inteiro visível.
- Reserva inteira visível.
- Nenhum canto cortado.
- Conjunto jogável ocupando 55% a 65% da largura.
- Faixas generosas de cenário nas laterais.
- Água e vegetação visíveis atrás.
- Canoa identificável, mas secundária.
- Ausência de oclusões sobre as casas.

Se houver céu e horizonte, mantenha-os em uma faixa pequena.

Não reduza o campo para mostrar um pôr do sol panorâmico.

Desative a profundidade de campo ou use um efeito mínimo.

Todas as casas devem permanecer nítidas.

## 24. Renderização

Use um motor disponível e adequado à execução.

Verifique cedo se ele oferece os recursos necessários para:

- Reflexos.
- Transparência ou transmissão da água.
- Sombras.
- Controle das anomalias.

Priorize:

1. Leitura do campo.
2. Integração entre margens e água.
3. Composição.
4. Iluminação.
5. Reflexos.
6. Materiais.
7. Detalhes.

Gere primeiro uma prévia em resolução reduzida.

Não finalize plantas aquáticas e pequenos detalhes antes de validar a câmera e os reflexos.

Use o gerenciamento de cor disponível na versão instalada para:

- Preservar detalhes nas sombras.
- Evitar reflexos estourados.
- Controlar a saturação do entardecer.

Não use o compositor para esconder problemas de geometria ou iluminação.

Render final:

- 1920 × 1080.
- PNG.
- Sem textos.
- Sem interface.
- Sem marca-d’água.
- Sem personagens.

## 25. Etapas de construção

### Etapa 1 — Inspeção e configuração

- Inspecionar o arquivo.
- Criar coleções.
- Definir parâmetros.
- Fixar a semente aleatória.
- Definir motor de renderização.

### Etapa 2 — Blockout

- Terreno.
- Campo.
- Reserva.
- Câmera.
- Nível de água.
- Canais principais.
- Árvores estruturais.
- Posição da cerca e da canoa.

Gerar uma prévia.

Verificar se o campo parece integrado à margem, não uma ilha retangular.

### Etapa 3 — Campo funcional

- Regularizar a grade.
- Criar sulcos.
- Validar posições.
- Construir reserva.
- Definir máscaras de exclusão.

### Etapa 4 — Margens e água

- Refinar o relevo.
- Ajustar interseções.
- Construir trechos rasos.
- Configurar material da água.
- Testar reflexos.

### Etapa 5 — Vegetação e vestígios

- Distribuir capim.
- Adicionar plantas aquáticas.
- Posicionar árvores.
- Construir cerca.
- Modelar e posicionar a canoa.

### Etapa 6 — Iluminação

- Configurar luz rasante.
- Ajustar preenchimento.
- Controlar reflexos intensos.
- Preservar leitura da grade.
- Adicionar profundidade atmosférica apenas se necessário.

### Etapa 7 — Horror sutil

- Implementar reflexo alterado.
- Criar ondulações junto à canoa.
- Criar passagem de capim amassado.

### Etapa 8 — Validação e entrega

- Executar checklist.
- Corrigir problemas.
- Salvar projeto.
- Renderizar imagem final.
- Registrar limitações.

## 26. Critérios de aceitação

### Campo e reserva

- [ ] Quantidade de casas corresponde à configuração.
- [ ] Hexágonos regulares e alinhados.
- [ ] Nenhuma casa faltando ou sobreposta.
- [ ] Divisões legíveis no render final.
- [ ] Ausência de conflitos coplanares.
- [ ] Campo integrado ao terreno.
- [ ] Reserva completa e visível.
- [ ] Água e vegetação não invadem posições.

### Terreno e água

- [ ] O campo não parece uma ilha retangular.
- [ ] Existe conexão de terra com a frente e uma lateral.
- [ ] As margens são baixas e irregulares.
- [ ] Os canais apresentam continuidade.
- [ ] Não existe um fosso uniforme.
- [ ] Não há interseções visivelmente incorretas.
- [ ] O terreno não termina dentro do enquadramento.
- [ ] A água não parece um espelho uniforme.

### Ambiente

- [ ] A paisagem permanece aberta.
- [ ] Há árvores espaçadas e grupos distantes.
- [ ] A vegetação não forma um muro ao redor do campo.
- [ ] A canoa é reconhecível e secundária.
- [ ] A cerca é discreta.
- [ ] Não há caveiras ou altares.
- [ ] Não há fauna confundível com unidades.

### Iluminação

- [ ] A origem da luz é coerente.
- [ ] O entardecer é reconhecível.
- [ ] Todas as casas permanecem legíveis.
- [ ] As sombras não apagam a grade.
- [ ] Os reflexos mais fortes ficam fora do campo.
- [ ] Não existe filtro laranja uniforme.
- [ ] A névoa não cobre a área jogável.
- [ ] As altas luzes não estão estouradas.

### Horror

- [ ] Existem três indícios discretos.
- [ ] Eles permanecem fora da área jogável.
- [ ] O reflexo alterado não parece um adesivo.
- [ ] Não há criaturas ou olhos brilhantes.
- [ ] As anomalias não dominam a composição.

## 27. Entregáveis

Salve em um diretório de saída disponível:

1. `pantanal_autochess.blend`
   - Cena organizada.
   - Materiais.
   - Iluminação.
   - Câmera.
   - Recursos locais incorporados quando aplicável.

2. `pantanal_autochess_final.png`
   - Render final 1920 × 1080.

3. `pantanal_autochess_preview.png`
   - Prévia de composição.

4. `README.md`
   - Versão do Blender.
   - Motor de renderização.
   - Parâmetros utilizados.
   - Quantidade de casas e posições de reserva.
   - Implementação da água e dos reflexos.
   - Decisões relevantes.
   - Limitações.
   - Localização dos arquivos.

Se a construção for automatizada por script, entregue também:

5. `build_pantanal.py`
   - Configuração centralizada.
   - Semente fixa.
   - Criação restrita à coleção do projeto.
   - Nova execução sem duplicações acidentais.
   - Sem dependências externas não declaradas.

Não exporte para um motor de jogo sem solicitação adicional.

## 28. Regra final

O resultado deve transmitir simultaneamente:

1. Um tabuleiro funcional.
2. Um trecho de terra firme integrado às áreas alagadas.
3. Uma paisagem aberta ao entardecer.
4. Uma presença invisível sugerida pela água.

Não resolva a integração criando um fosso.

Não resolva o entardecer cobrindo tudo de laranja.

Não resolva o horror escurecendo a imagem até perder informação.

Não resolva os reflexos transformando toda a água em espelho.

A sensação final deve ser de um lugar tranquilo demais, onde a água parece guardar movimentos e formas que não correspondem inteiramente ao que existe nas margens.