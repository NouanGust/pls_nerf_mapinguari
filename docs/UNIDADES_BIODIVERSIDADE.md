# Unidades de fauna e flora — Folchess

Atualizado em 15/10/2026. Este documento registra os novos recursos de unidade e espécies pesquisadas para futuras adições. Os dados de conservação servem como referência de contexto e devem ser revistos com a lista oficial mais recente antes de uma publicação.

## Unidades adicionadas

O elenco passa de 22 para **37 recursos de unidade**. As novas unidades usam ícone placeholder até a produção de arte. Foram incluídas afinidades de sinergia `Fauna` e `Flora`, e um campo separado de biomas para guardar habitat sem confundir habitat com papel de combate.

| Unidade | Afinidade | Origem / bioma | Função proposta |
| --- | --- | --- | --- |
| Onça-pintada | Fauna | Amazônico, Pantaneiro | Caçador / DPS |
| Tamanduá-bandeira | Fauna | Cerrado, Pantaneiro | Tank / Protetor da Mata |
| Lobo-guará | Fauna e Flora | Cerrado, Pantaneiro | Caçador / Suporte; ponte de dispersão de sementes |
| Mandacaru | Flora | Caatinga, Sertanejo | Tank / Protetor da Mata |
| Vitória-régia | Flora | Amazônico | Aquático / Suporte |
| Sumaúma | Flora | Amazônico | Tank / Protetor da Mata |
| Pau-brasil | Flora | Mata Atlântica, Litorâneo | Tank / Protetor da Mata |
| Brinco-de-princesa (*Fuchsia alpestris*) | Flora | Mata Atlântica | Suporte / Encantado |

Boiúna e Mboi-Guaçu também receberam afinidade `Fauna`, como criaturas folclóricas com forma de serpente. O lobo-guará tem `Fauna` e `Flora` porque dispersa sementes ao consumir frutos; essa ponte é uma interpretação de jogo baseada em sua ecologia. Assim, a lista atual tem **5 unidades de Fauna** e **6 de Flora**.

### Resources adicionados na segunda leva

| Unidade | Afinidade | Origem / bioma | Função proposta |
| --- | --- | --- | --- |
| Ararinha-azul | Fauna | Caatinga, Sertanejo | Caçador / Suporte |
| Arara-azul-de-lear | Fauna | Caatinga, Sertanejo | Caçador / DPS |
| Mutum-de-alagoas | Fauna | Mata Atlântica, Litorâneo | Tank / Suporte |
| Tatu-bola-do-nordeste | Fauna | Caatinga, Sertanejo | Tank / Protetor da Mata |
| Palmito-juçara | Flora | Mata Atlântica, Litorâneo | Suporte / Místico |
| Araucária | Flora | Mata Atlântica | Tank / Protetor da Mata |
| Guaraná | Flora | Amazônico | Místico / Suporte |

## Sinergias após a inclusão

Com as duas afinidades e três origens de bioma novas (Cerrado, Caatinga e Mata Atlântica), existem **21 etiquetas candidatas a sinergia**: 9 origens, 10 classes e 2 afinidades. Fauna e Flora contam agora 9 unidades cada, permitindo planejar patamares 2/4/6. As origens de bioma novas cresceram: Cerrado 2, Mata Atlântica 5 e Caatinga 4. O patamar de Cerrado ainda precisa de mais elenco para oferecer progressão longa.

O sistema de combate ainda não ativa os bônus de sinergia. As afinidades agora estão armazenadas e podem ser consultadas pelos dados/`UnitSpawner`; descrições de habilidades e números-base são propostas de protótipo, não efeitos já validados em combate. As classes continuam com as etiquetas antigas de função, e alguns papéis terão de ser balanceados porque Suporte, Tank e Protetor da Mata já são frequentes.

## Espécies adicionais pesquisadas

### Fauna

| Candidata | Referência de conservação | Ideia de unidade |
| --- | --- | --- |
| Ararinha-azul (*Cyanopsitta spixii*) | Resource criado. CR na lista nacional indicada pelo ICMBio; foi considerada extinta na natureza e está em manejo/reintrodução. | Unidade de alto tier da Caatinga, atiradora ou suporte; habilidade de reagrupamento. |
| Arara-azul-de-lear (*Anodorhynchus leari*) | Resource criado. Em Perigo (EN), segundo o programa de manejo populacional do ICMBio. | Atiradora de longo alcance da Caatinga; bônus para aliados voadores ou de Fauna. |
| Mutum-de-alagoas (*Pauxi mitu*) | Resource criado. Extinto na natureza (EW) nas referências do PAN do ICMBio; há esforços de reprodução e reintrodução. | Unidade lendária da Mata Atlântica nordestina, com foco em proteção/retorno de aliados. |
| Tatu-bola-do-nordeste (*Tolypeutes tricinctus*) | Resource criado. EN na categoria apresentada pelo ICMBio para o PAN Tamanduá e Tatus; a página ressalva que a categoria acompanha a lista vigente à época do PAN. | Tanque da Caatinga que se fecha na carapaça para reduzir dano. |

### Flora

| Candidata | Referência de conservação | Ideia de unidade |
| --- | --- | --- |
| Palmito-juçara (*Euterpe edulis*) | Resource criado. Vulnerável (VU) na avaliação do CNCFlora/Jardim Botânico do Rio de Janeiro (2012). | Suporte da Mata Atlântica que recupera vida ou fortalece aliados próximos. |
| Araucária (*Araucaria angustifolia*) | Resource criado. Já constou como Em Perigo (EN) na lista nacional citada pelo CNCFlora; a avaliação referenciada é antiga e precisa ser atualizada antes de fixar a categoria atual. | Guardiã do Sul, Tank/Flora com área de proteção. |
| Guaraná (*Paullinia cupana*) | Resource criado. Planta nativa da Amazônia; não foi adicionada como espécie ameaçada. | Suporte que energiza os aliados, inspirado no uso tradicional e na cultura do guaraná. |

O Pau-brasil já entrou no elenco; a avaliação do CNCFlora o classifica como Criticamente em Perigo (CR). O Brinco-de-princesa foi cadastrado como *Fuchsia alpestris*, espécie endêmica do Brasil e Vulnerável (VU) na avaliação do CNCFlora de 2017. A Embrapa descreve *Paullinia cupana* como planta nativa da Amazônia e cultura genuinamente brasileira e amazonense.

## Fontes

- [ICMBio — Fauna brasileira ameaçada e atualização das listas](https://www.gov.br/icmbio/pt-br/assuntos/biodiversidade/fauna-brasileira)
- [ICMBio — Ararinha-azul](https://www.gov.br/icmbio/pt-br/assuntos/biodiversidade/programa-de-manejo-populacional/pmp-ararinha-azul/ararinha-azul)
- [ICMBio — Arara-azul-de-lear](https://www.gov.br/icmbio/pt-br/assuntos/biodiversidade/programa-de-manejo-populacional/pmp-ararinha-azul-de-lear)
- [ICMBio — Mutum-de-alagoas, plano de ação](https://www.gov.br/icmbio/pt-br/assuntos/biodiversidade/pan/pan-mutum-de-alagoas/1-ciclo/pan-mutum-de-alagoas-sumario.pdf)
- [ICMBio — PAN Tamanduá e Tatus](https://www.gov.br/icmbio/pt-br/assuntos/biodiversidade/pan/pan-tamandua-e-tatus)
- [ICMBio — Lobo-guará e dispersão de sementes](https://www.gov.br/icmbio/pt-br/assuntos/biodiversidade/pan/pan-canideos/1-ciclo/produtos/2020-pan-canideos-produtores-rurais-canideos-silvestres.pdf)
- [CNCFlora/JBRJ — Pau-brasil (*Paubrasilia echinata*), CR](https://cncflora.jbrj.gov.br/ficha/602728)
- [CNCFlora/JBRJ — Brinco-de-princesa (*Fuchsia alpestris*), VU](https://proflora.jbrj.gov.br/html/Fuchsia%20alpestris_2017.html)
- [CNCFlora/JBRJ — Palmito-juçara (*Euterpe edulis*), VU](https://cncflora.jbrj.gov.br/ficha/15712)
- [CNCFlora/JBRJ — Araucária (*Araucaria angustifolia*)](https://cncflora.jbrj.gov.br/ficha/33971)
- [Embrapa Amazônia Ocidental — guaranazeiro (*Paullinia cupana*)](https://www.embrapa.br/en/web/amazonia-ocidental/busca-de-projetos/-/projeto/8033/melhoramento-genetico-do-guaranazeiro)
