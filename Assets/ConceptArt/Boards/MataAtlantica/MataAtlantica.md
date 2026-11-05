# Agente Blender — Arena de Autochess na Mata Atlântica

## 1. Missão

Crie no Blender uma cena 3D de ambiente para um jogo de autochess de horror folclórico brasileiro, ambientada no interior de uma Mata Atlântica fechada, densa e úmida, durante a noite.

Execute a construção da cena, não apenas descreva como ela poderia ser feita.

O resultado deve apresentar:

- Um tabuleiro hexagonal completo, funcional e legível.
- Uma faixa frontal de reserva de unidades.
- Terreno contínuo integrando a área jogável à floresta.
- Árvores irregulares, vegetação sobreposta, cipós e raízes.
- Um pequeno riacho lateral com pedras úmidas.
- Luz da lua atravessando pequenos intervalos entre as folhas.
- Indícios discretos de horror folclórico.
- Ausência de personagens, unidades e criaturas.

O cenário não deve parecer uma clareira.

A floresta continua ao redor e acima do campo. A visibilidade do tabuleiro deve resultar do posicionamento da câmera e do controle das oclusões, não de uma grande abertura na copa.

## 2. Prioridades

Resolva os objetivos nesta ordem:

1. Tabuleiro completo e legível.
2. Reserva frontal totalmente visível.
3. Sensação de mata fechada e densa.
4. Iluminação lunar coerente.
5. Materiais úmidos e profundidade.
6. Horror ambiental sutil.
7. Detalhes decorativos.

Se houver conflito entre vegetação e leitura do jogo, reposicione a vegetação sem transformar a floresta em um espaço aberto.

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

Se não for possível executar o Blender, informe a limitação. Não apresente uma descrição como se fosse uma cena concluída.

## 4. Referências e interpretação

Use as fotografias da Mata Atlântica e do riacho fornecidas pelo usuário para orientar:

- Troncos irregulares.
- Cipós pendentes.
- Vegetação em diferentes alturas.
- Samambaias e folhas largas.
- Pedras parcialmente cobertas por musgo.
- Água rasa entre pedras.
- Solo úmido com folhas em decomposição.

Transforme a iluminação diurna das referências em uma cena noturna.

Use a referência do protótipo do jogo somente para:

- Campo hexagonal central.
- Reserva na frente.
- Cenário nas laterais e no fundo.

Não copie:

- Árvores geométricas.
- Muralhas.
- Tochas.
- Plataformas elevadas.
- Cores ou acabamento plástico.

Se as imagens não estiverem acessíveis, siga a descrição deste documento e registre a ausência.

## 5. Parâmetros configuráveis

Centralize os parâmetros de geração em uma configuração única.

| Parâmetro | Valor inicial |
|---|---|
| Nome da cena | `MataAtlantica_Autochess` |
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
| Horário visual | Noite |
| Direção visual da lua | Alto à esquerda, atrás do campo |

Esses valores são padrões de implementação, não medidas obrigatórias das referências.

Se houver um tabuleiro existente ou dimensões fornecidas pelo usuário, preserve essas dimensões.

## 6. Organização da cena

Crie a coleção principal:

`MATA_ATLANTICA_ENV`

Organize os objetos em:

- `00_CONTROLS`
- `01_TERRAIN`
- `02_BOARD`
- `03_RESERVE`
- `04_TREES`
- `05_CANOPY`
- `06_UNDERGROWTH`
- `07_ROOTS_AND_VINES`
- `08_STREAM_AND_ROCKS`
- `09_HORROR_DETAILS`
- `10_LIGHTS`
- `11_CAMERAS`

Use nomes claros, como:

- `Terrain_Main`
- `Board_Hex_00_00`
- `Reserve_Slot_00`
- `Tree_Variant_A`
- `Canopy_Cluster_A`
- `Fern_Cluster_A`
- `Vine_Variant_A`
- `Stream_Surface`
- `Rock_Mossy_A`
- `Camera_Game`
- `Light_Moon_Key`

Mantenha a cena editável. Não una todo o ambiente em uma única malha.

## 7. Conceito espacial — mata fechada, não clareira

Construa o campo como um trecho de chão firme sob a floresta.

A área jogável permanece livre de obstáculos volumosos, mas a cobertura vegetal continua acima dela.

Não represente:

- Um círculo de árvores ao redor de um espaço vazio.
- Uma abertura circular na copa sobre o campo.
- Um grande corredor até o horizonte.
- Céu aberto dominando o enquadramento.
- Um jardim organizado.
- Uma arena construída com vegetação ao redor.

Crie densidade usando:

- Sobreposição de troncos.
- Copas em alturas diferentes.
- Vegetação intermediária.
- Cipós.
- Galhos elevados.
- Massas escuras de folhas ao fundo.
- Passagens estreitas que desaparecem rapidamente.

A câmera deve estar dentro da floresta, abaixo da copa principal.

## 8. Terreno contínuo

Crie um terreno que se estenda além do enquadramento.

Integre:

- Campo de combate.
- Reserva.
- Margens vegetadas.
- Riacho lateral.
- Floresta de fundo.

### Área jogável

- Relativamente plana.
- Terra compactada.
- Textura simples.
- Sem pedras grandes.
- Sem raízes volumosas.
- Sem vegetação alta.
- Sem poças extensas.

### Área externa

Introduza gradualmente:

- Pequenos desníveis.
- Depressões úmidas.
- Folhas acumuladas.
- Raízes expostas.
- Pedras.
- Margens irregulares do riacho.

Não aplique deslocamento ou ruído de relevo com a mesma intensidade em toda a superfície.

Não crie uma plataforma com laterais aparentes.

## 9. Grade hexagonal

Crie por padrão 8 colunas e 8 fileiras de hexágonos regulares.

Use uma única convenção geométrica.

Para hexágonos com ponta para cima e raio `R`, use:

- Espaçamento horizontal entre centros: `sqrt(3) * R`.
- Espaçamento vertical entre fileiras: `1.5 * R`.
- Deslocamento horizontal de meia célula em fileiras alternadas.

Centralize a grade após calcular seus limites.

O campo deve ter contorno geral aproximadamente retangular, preservando a borda natural das casas hexagonais.

Não corte as casas externas para forçar um retângulo perfeito.

### Aparência

As casas devem parecer marcadas no solo, não peças empilhadas.

Use:

- Sulcos rasos.
- Variações suaves de compactação.
- Pequenas diferenças de tonalidade.
- Desgaste discreto nas bordas.

Faixa inicial sugerida para os sulcos:

- Largura: 0,015 a 0,03 m.
- Profundidade visual: 0,005 a 0,015 m.

Ajuste após observar a câmera final.

A superfície pode parecer úmida, mas deve permanecer predominantemente fosca.

Não use:

- Emissão.
- Contornos luminosos.
- Borda de pedra.
- Mosaico ornamental.
- Elevação evidente de cada casa.
- Reflexos fortes apagando a grade.

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

Centralize a reserva em relação ao campo.

Não crie degraus, pedestais ou uma plataforma frontal.

## 11. Máscaras de exclusão e oclusão

Defina regiões de exclusão para o espalhamento ambiental:

1. Interior das casas.
2. Faixa de reserva.
3. Margem de segurança ao redor do conjunto jogável.
4. Corredor visual entre a câmera e a borda frontal.

Use margem inicial de aproximadamente 0,5 m, ajustável conforme a escala.

A exclusão deve considerar o volume final dos objetos.

Um objeto com origem fora do campo não pode projetar folhas, raízes ou galhos sobre as casas.

### Copa sobre o campo

A copa pode continuar acima do conjunto jogável, desde que não se interponha visualmente entre a câmera e o tabuleiro.

Resolva esse conflito com altura, posição e arquitetura dos galhos.

Não resolva removendo toda a copa central.

Não dependa de ocultar artificialmente grandes conjuntos de folhas apenas da câmera para simular uma solução espacial.

## 12. Árvores

Crie pelo menos 5 variantes de árvores, com diferenças em:

- Altura.
- Espessura do tronco.
- Inclinação.
- Bifurcações.
- Curvatura.
- Arquitetura da copa.
- Quantidade de cipós.

Use troncos irregulares, sem aparência de cilindros perfeitos.

### Distribuição

- Árvores maiores nas laterais externas e ao fundo.
- Troncos intermediários sobrepostos em profundidade.
- Grupos assimétricos.
- Pequenas passagens entre massas vegetais.
- Nenhum grande tronco bloqueando a frente.

Não distribua árvores em um círculo uniforme.

### Materiais

Use:

- Marrom escuro.
- Cinza amarronzado.
- Manchas discretas de verde.
- Variação de casca.
- Umidade localizada.

Não faça todos os troncos parecerem cobertos de musgo.

Não modele rostos, mãos ou silhuetas humanoides.

## 13. Copa e folhagem elevada

Crie massas de folhas com volumes reconhecíveis.

Use instâncias e grupos reutilizáveis quando adequado.

Evite preencher a copa apenas com placas planas facilmente perceptíveis pela câmera.

Distribua pequenas aberturas irregulares entre folhas.

Essas aberturas permitem entradas localizadas de luz, mas não formam um grande buraco sobre o tabuleiro.

Mantenha continuidade visual entre:

- Copas laterais.
- Galhos superiores.
- Folhagem de fundo.

A copa deve ser percebida mesmo quando parte dela fica fora do enquadramento.

## 14. Vegetação baixa

Crie variantes de:

- Samambaias.
- Plantas de folhas largas.
- Pequenos arbustos.
- Mudas de árvores.
- Grupos de folhas caídas.

Distribua em camadas e manchas assimétricas.

Use:

- Plantas baixas próximas do campo.
- Massas intermediárias nas laterais.
- Vegetação mais sobreposta ao fundo.

Não transforme toda folha em um elemento gigante.

Não use a mesma escala, rotação ou densidade em todos os grupos.

Evite ruído de pequenos detalhes sem contribuição na câmera final.

## 15. Raízes e cipós

Crie raízes expostas nas áreas externas ao campo.

Elas devem:

- Acompanhar o relevo.
- Apresentar espessuras variadas.
- Desaparecer sob folhas ou terra.
- Conectar-se visualmente aos troncos.

Não crie uma moldura de raízes perfeitamente contornando o tabuleiro.

Use cipós com curvas assimétricas e espessura variável.

Alguns podem pender em regiões laterais e ao fundo.

Nenhum cipó deve atravessar visualmente a grade ou a reserva.

## 16. Riacho e pedras

Crie um riacho pequeno em uma lateral externa.

Ele deve:

- Percorrer apenas parte do cenário.
- Apresentar margens irregulares.
- Desaparecer entre vegetação e pedras.
- Permanecer secundário ao tabuleiro.

Não atravesse o campo ou a reserva.

Não crie um fosso ou transforme o tabuleiro em ilha.

### Água

Use superfície com ondulações discretas.

Combine:

- Áreas escuras.
- Reflexos fragmentados.
- Pequenos trechos rasos.
- Variação visual de profundidade.

Não use uma cor azul saturada.

Não transforme a água em um espelho perfeito.

### Pedras

Crie pelo menos 4 variantes de pedras irregulares.

Distribua algumas parcialmente submersas.

Use musgo de maneira localizada, principalmente em superfícies protegidas e úmidas.

Evite pedras idênticas e contornos perfeitamente arredondados.

## 17. Vestígios humanos

Inclua apenas um vestígio discreto:

- Um pedaço de tecido desbotado preso a um galho baixo, próximo de uma passagem lateral.

Ele deve:

- Ter cor pouco saturada.
- Parecer envelhecido.
- Quase se confundir com folhas mortas.
- Permanecer fora da área jogável.

Não inclua inscrições, símbolos, função ritual explícita ou emissão.

Não crie altares, totens, ruínas ou objetos culturais genéricos para comunicar horror.

## 18. Horror folclórico ambiental

Implemente três indícios discretos:

### A. Pegadas de orientação suspeita

Modele um pequeno conjunto de pegadas descalças na lama próxima ao riacho.

A orientação dos pés deve contradizer sutilmente o arrasto do sedimento.

As marcas desaparecem entre raízes e não chegam ao campo.

Use geometria rasa ou alterações de material.

Não inclua sangue.

### B. Cipós em nós improváveis

Em um grupo lateral, crie cipós entrelaçados de maneira pouco natural.

O conjunto deve parecer parte da vegetação.

Não forme letras, rostos, pentagramas ou símbolos geométricos.

### C. Passagem que parece retornar

Repita parcialmente uma combinação de dois troncos e uma pedra em uma camada distante.

A repetição deve sugerir desorientação, não duplicação óbvia de assets.

Esses indícios são recursos ficcionais de direção de arte.

Não apresente a cena como representação literal de uma tradição específica.

Não adicione:

- Criaturas.
- Figuras humanoides escondidas.
- Olhos brilhantes.
- Rostos nas árvores.
- Cadáveres.
- Caveiras decorativas.
- Mãos saindo da água.

## 19. Materiais

Estilo:

- 3D estilizado.
- Acabamento pictórico sombrio.
- Volumes claros.
- Materiais reconhecíveis.
- Umidade controlada.

Paleta:

- Marrom de terra úmida.
- Verde-musgo.
- Verde-oliva.
- Verde profundo dessaturado.
- Verde-acinzentado.
- Cinza frio.
- Prata discreta nos acentos lunares.

Use materiais procedurais quando não houver texturas locais.

Mantenha escala coerente das texturas.

Evite:

- Mesmo ruído em todos os materiais.
- Bump exagerado.
- Terra envernizada.
- Folhas inteiramente brilhantes.
- Emissão em plantas.
- Filtro azul cobrindo toda a cena.

## 20. Iluminação lunar

A lua está fora do enquadramento, no alto à esquerda e ligeiramente atrás do campo.

Toda a iluminação direcional deve respeitar essa origem.

Não é necessário modelar a lua.

### Camada 1 — Luz lunar principal

Use uma luz direcional com tonalidade cinza-prateada e leve tendência fria.

Não use azul intenso ou ciano.

Ela deve atingir seletivamente:

- Bordas superiores de folhas.
- Faces de troncos voltadas para a luz.
- Superfícies de algumas pedras.
- Trechos do riacho.
- Partes do terreno.

A copa fragmenta essa luz.

Não crie um círculo claro no centro ou um holofote sobre o campo.

### Camada 2 — Preenchimento ambiente

Use preenchimento suave para preservar a leitura de:

- Todas as casas.
- Sulcos.
- Reserva.
- Terreno.
- Troncos próximos.

O tabuleiro permanece em valores médios escuros, não em preto.

Se precisar de luz auxiliar, mantenha contribuição ampla e discreta.

Não deixe a luz parecer uma lâmpada escondida junto ao campo.

Preserve os marrons do solo e a variedade dos verdes.

### Camada 3 — Acentos úmidos

Adicione pequenos reflexos em:

- Algumas bordas de folhas.
- Faces superiores de pedras molhadas.
- Trechos de casca.
- Superfície do riacho.

Esses reflexos devem ser localizados.

Não ilumine todas as superfícies com a mesma intensidade.

### Camada 4 — Profundidade

Reduza o contraste nas camadas distantes.

Preserve sombras profundas entre árvores, mas mantenha informação nas formas próximas.

Não transforme as laterais em uma moldura preta sem detalhes.

## 21. Feixes de luz e atmosfera

Crie no máximo dois ou três feixes perceptíveis nas laterais e ao fundo.

Eles devem:

- Ter larguras diferentes.
- Ser interrompidos por folhas.
- Perder intensidade em profundidade.
- Aparecer apenas onde encontram umidade suspensa.

Se necessário, use volumes locais e limitados.

Não preencha toda a cena com um cubo de névoa densa.

Não use cones sólidos de luz.

Não coloque névoa sobre o tabuleiro.

O campo deve permanecer nítido.

Se o custo dos volumes comprometer a execução, priorize sombras, manchas de luz e profundidade antes dos feixes.

## 22. Sombras sobre o campo

As sombras da vegetação devem ser:

- Suaves.
- Esparsas.
- Pouco contrastadas.
- Diferentes visualmente dos sulcos da grade.

Não projete uma rede densa de galhos sobre os hexágonos.

Não deixe uma grande sombra atravessar toda a arena.

Ajuste luz, árvores e câmera se a leitura ficar prejudicada.

Não represente sombras em forma de criatura.

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
- Cenário generoso nas laterais.
- Vegetação sobreposta ao fundo.
- Riacho parcialmente visível.
- Ausência de oclusões sobre casas.

A câmera deve estar abaixo da copa principal.

Não aumente sua altura até parecer uma vista acima das árvores.

Desative a profundidade de campo ou use um efeito mínimo.

Todas as casas devem permanecer nítidas.

## 24. Renderização

Use um motor disponível e adequado à execução.

Priorize:

1. Leitura do campo.
2. Densidade da floresta.
3. Iluminação.
4. Silhuetas.
5. Materiais.
6. Detalhes.

Gere primeiro uma prévia em resolução reduzida.

Não finalize vegetação detalhada antes de validar a câmera.

Use o gerenciamento de cor disponível na versão instalada para preservar detalhes nas sombras e controlar reflexos intensos.

Não use o compositor para esconder problemas de iluminação ou geometria.

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

### Etapa 2 — Blockout

- Terreno.
- Campo.
- Reserva.
- Câmera.
- Troncos principais.
- Volumes de copa.
- Traçado do riacho.

Gerar uma prévia.

Verificar imediatamente se o ambiente parece mata fechada ou clareira.

### Etapa 3 — Campo funcional

- Regularizar a grade.
- Criar sulcos.
- Validar posições.
- Construir reserva.
- Definir máscaras de exclusão.

### Etapa 4 — Estrutura da floresta

- Modelar variantes de árvores.
- Construir camadas de vegetação.
- Posicionar copa.
- Adicionar raízes e cipós.
- Verificar oclusões pela câmera.

### Etapa 5 — Água e materiais

- Construir riacho.
- Distribuir pedras.
- Aplicar materiais.
- Adicionar umidade localizada.

### Etapa 6 — Iluminação

- Configurar origem lunar.
- Ajustar preenchimento.
- Controlar sombras sobre o campo.
- Adicionar reflexos.
- Adicionar atmosfera apenas se necessário.

### Etapa 7 — Horror sutil

- Criar pegadas.
- Criar nós de cipós.
- Criar repetição espacial.
- Adicionar tecido discreto.

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
- [ ] Nenhuma vegetação bloqueia posições.

### Floresta

- [ ] O ambiente parece mata fechada, não clareira.
- [ ] A copa sugere continuidade acima do campo.
- [ ] Não existe abertura circular sobre a arena.
- [ ] Existem várias camadas de troncos e vegetação.
- [ ] Não há distribuição simétrica de árvores.
- [ ] Galhos e folhas não escondem o tabuleiro.
- [ ] O terreno não termina dentro do enquadramento.

### Água

- [ ] O riacho é secundário.
- [ ] Não atravessa campo ou reserva.
- [ ] Não forma um fosso.
- [ ] Reflexos são fragmentados.
- [ ] Não há aparência de água azul de fantasia.

### Iluminação

- [ ] A direção lunar é coerente.
- [ ] Todas as casas permanecem legíveis.
- [ ] A imagem parece noturna.
- [ ] Não existe filtro azul uniforme.
- [ ] As sombras não apagam a grade.
- [ ] Não há círculo de holofote sobre o campo.
- [ ] Os reflexos úmidos são localizados.
- [ ] A névoa não cobre a área jogável.

### Horror

- [ ] Existem três indícios discretos.
- [ ] Eles permanecem fora da área jogável.
- [ ] Não dominam a composição.
- [ ] Não existem criaturas ou olhos brilhantes.
- [ ] Não existem altares ou símbolos genéricos.

## 27. Entregáveis

Salve em um diretório de saída disponível:

1. `mata_atlantica_autochess.blend`
   - Cena organizada.
   - Materiais.
   - Iluminação.
   - Câmera.
   - Recursos locais incorporados quando aplicável.

2. `mata_atlantica_autochess_final.png`
   - Render final 1920 × 1080.

3. `mata_atlantica_autochess_preview.png`
   - Prévia de composição.

4. `README.md`
   - Versão do Blender.
   - Motor de renderização.
   - Parâmetros utilizados.
   - Quantidade de casas e posições de reserva.
   - Decisões relevantes.
   - Limitações.
   - Localização dos arquivos.

Se a construção for automatizada por script, entregue também:

5. `build_mata_atlantica.py`
   - Configuração centralizada.
   - Semente fixa.
   - Criação restrita à coleção do projeto.
   - Nova execução sem duplicações acidentais.
   - Sem dependências externas não declaradas.

Não exporte para um motor de jogo sem solicitação adicional.

## 28. Regra final

O resultado deve transmitir simultaneamente:

1. Um tabuleiro funcional.
2. Uma mata fechada.
3. Uma noite iluminada pela lua.
4. Uma presença invisível percebida nos vestígios.

Não resolva a legibilidade transformando a floresta em clareira.

Não resolva o horror escurecendo a imagem até perder informação.

Não resolva a densidade cobrindo o tabuleiro com folhas.

A sensação final deve ser de um campo marcado no interior de uma floresta que continua acima dele — e que parece observar quem entrou.