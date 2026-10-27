# Pesquisa de lendas e propostas de unidades por origem

**Data:** 27/10/2026  
**Status:** pesquisa e proposta de design; nenhuma unidade, habilidade, sinergia ou campanha foi alterada.  
**Objetivo:** ampliar as opções para todas as origens do Folchess e revisar a concentração da pesquisa anterior em Urbano.

## 1. Critério de classificação

A pesquisa passa a abranger **lendas regionais, narrativas folclóricas e personagens do cordel**, além de lendas urbanas. Esse recorte é necessário para representar florestas, rios, campos e tradições sertanejas.

Cada ficha distingue:

1. **Tradição registrada:** o que a fonte relata sobre a personagem e onde essa narrativa circula. Isso documenta uma tradição, não comprova acontecimentos sobrenaturais.
2. **Origem proposta no jogo:** uma única etiqueta de composição, escolhida para uma versão específica da personagem. Não implica exclusividade cultural ou distribuição biológica.
3. **Adaptação de combate:** habilidade, função, classes, custo e aparência sugeridos nesta pesquisa. São criações de design, não atributos históricos da lenda nem valores já balanceados.

Uma lenda de Recife não vira Litorâneo apenas por Recife estar no litoral. Da mesma forma, uma personagem de Minas Gerais não vira automaticamente Cerrado, nem toda narrativa nordestina pertence à Caatinga. A ligação com a paisagem ou com uma tradição regional precisa estar explicada.

### Definição editorial das origens

As etiquetas abaixo já existem no jogo; a coluna central estabelece o critério recomendado para esta pesquisa.

| Origem exata | Critério para novas lendas | Unidades atuais | Patamares atuais |
| --- | --- | ---: | --- |
| Amazônico | Versões relacionadas às florestas, rios e comunidades da Amazônia. | 12 | 3/6 |
| Caatinga | Versões associadas ao semiárido e a suas paisagens, incluindo os rios que o atravessam. | 4 | 2/4 |
| Cerrado | Versões ligadas aos campos, matas e tradições do Brasil Central; adaptações nacionais precisam de justificativa explícita. | 4 | 2/4 |
| Pantaneiro | Narrativas documentadas entre comunidades pantaneiras, não simplesmente qualquer criatura aquática. | 7 | 3/5 |
| Mata Atlântica | Versões relacionadas a florestas e comunidades inseridas nessa paisagem, explicitando o recorte local. | 7 | 3/5 |
| Litorâneo | Personagens cuja identidade depende do mar, de praias, ilhas, navegação costeira ou mangues. | 5 | 2/4 |
| Sertanejo | Tradições culturais do interior, do cordel, das fazendas e dos vaqueiros. Não é sinônimo de Caatinga. | 1 | 1 |
| Urbano | Assombrações cuja narrativa depende de escolas, bairros, cemitérios urbanos, bailes ou circulação na mídia. | 5 | 2/4 |

**Base local conferida:** 45 arquivos em `resources/units`, regras em `Scripts/Systems/synergy_system.gd` e campanhas em `Scripts/Systems/region_rosters.gd`. Contagem referente ao estado de trabalho desta data, incluindo alterações locais já existentes.

O jogo exige **uma origem e uma ou duas classes** por unidade. As seis campanhas não equivalem às oito origens: a campanha Pantanal corresponde à origem Pantaneiro, Amazônia a Amazônico e Litoral a Litorâneo. Urbano e Sertanejo não possuem campanhas próprias atualmente. Selecionar a origem de uma unidade também não a adiciona automaticamente à formação inimiga de uma campanha.

## 2. Revisão das sete propostas anteriores

As seis personagens claramente urbanas continuam úteis. A solução para ampliar a distribuição é acrescentar repertório regional, sem retirar delas a identidade que motivou a escolha.

| Personagem | Origem proposta revisada | Decisão e justificativa | Conceito de unidade preservado |
| --- | --- | --- | --- |
| Perna Cabeluda | Urbano | Manter. O elemento central são as aparições e agressões nas ruas do Recife, não o mar. [Fonte](https://periodicos.unicap.br/paralellus/article/view/2318). | 2g, Porradeiro; Assombração/DPS; rasteira com dano e controle breve. |
| Loira do Banheiro | Urbano | Manter. Rituais escolares e aparições em banheiros são o núcleo da narrativa. [Fonte](https://conexao.ufrj.br/2008/11/lenda-sobre-loira-do-banheiro-e-tema-de-pesquisa/). | 3g, Conjurador; Assombração/Místico; explosão de um espelho após três sinais. |
| Num-se-Pode | Urbano | Manter. Na versão pesquisada, ruas e lampiões da antiga Teresina definem a aparição. A localização no Piauí não basta para classificá-la como Caatinga. [Fonte](https://www.geleiatotal.com.br/2023/03/22/cidade-invisivel-em-teresina/). | 4g, Tank; Assombração/Tank; crescimento, escudo e controle próximo. |
| Chupa-Cabra | Sertanejo, como adaptação | Rever. Os relatos brasileiros pesquisados envolvem ataques atribuídos à criatura em áreas de criação de animais no interior de SP e PR. O enquadramento em Sertanejo é editorial, pelo cenário rural; a fonte não o identifica como lenda especificamente sertaneja. Reserva de menor prioridade. [Fonte](https://www1.folha.uol.com.br/fol/geral/gx035545.htm). | 3g, Assassino; Caçador/DPS; perseguição de feridos e recuperação proporcional ao dano. |
| Loira do Bonfim | Urbano | Manter. A relação com o cemitério e as caronas em Belo Horizonte define a personagem. [Fonte](https://portalbelohorizonte.com.br/eventos/encontro/cultural/passeio-pela-historia-loira-do-bonfim). | 3g, Suporte; Assombração/Suporte; atração curta de um inimigo. |
| Capeta do Vilarinho | Urbano | Manter. Sua identidade está nos bailes de Venda Nova, não em uma paisagem de Cerrado. [Fonte](https://www.hojeemdia.com.br/minas/existe-um-tunel-debaixo-do-colegio-arnaldo-veja-esta-e-outras-lendas-urbanas-de-bh-1.468198?amp=1). | 4g, Suporte; Místico/Suporte; dança que acelera aliados próximos. |
| Bebê-Diabo | Urbano | Manter. É uma narrativa popularizada pela cobertura sensacionalista do Notícias Populares em 1975. [Fonte](https://vejasp.abril.com.br/coluna/memoria/a-manchete-que-mexeu-com-sao-paulo-nos-anos-70-o-bebe-diabo/). | 1g, Conjurador; Místico; grito mágico de alcance curto. |

**Resultado:** seis propostas urbanas preservadas e uma adaptação sertaneja opcional. O Chupa-Cabra não deve ser apresentado no bestiário como originalmente exclusivo do sertão brasileiro.

## 3. Quatorze novas candidatas para as demais origens

Cada linha é uma proposta distinta. Custos e classes são pontos iniciais para prototipagem.

| Origem | Personagem | Custo | Função | Classes | Identidade de combate |
| --- | --- | ---: | --- | --- | --- |
| Amazônico | Boto Encantado | 3g | Suporte | Aquático, Metamorfo | Alterna forma humana e boto para proteger aliados. |
| Amazônico | Capelobo | 4g | Porradeiro | Caçador, DPS | Pressiona um alvo e se recupera ao acertar sua habilidade. |
| Caatinga | Caboclo d'Água do São Francisco | 3g | Tank | Aquático, Tank | Resiste na frente e interrompe com uma onda curta. |
| Caatinga | Cabra Cabriola | 2g | Porradeiro | Assombração, DPS | Cabeçada seguida de reforço temporário dos ataques. |
| Cerrado | Pai do Mato | 3g | Tank | Protetor da Mata, Tank | Protege a si e um aliado próximo. |
| Cerrado | Boitatá | 4g | Conjurador | Místico, Protetor da Mata | Dano mágico em uma faixa de fogo sinalizada. |
| Pantaneiro | Mãozão | 3g | Tank | Assombração, Tank | Interrompe um inimigo com uma grande palmada. |
| Pantaneiro | Anta Bondosa | 2g | Suporte | Encantado, Suporte | Socorre um aliado ferido e protege sua recuperação. |
| Mata Atlântica | Saci-Pererê | 2g | Suporte | Encantado, Suporte | Redemoinho que atrapalha inimigos e protege um aliado. |
| Mata Atlântica | Curupira | 3g | Suporte | Protetor da Mata, Suporte | Pegadas falsas retardam o avanço adversário. |
| Litorâneo | João Galafuz | 2g | Conjurador | Aquático, Místico | Clarão marítimo com dano após um aviso visível. |
| Litorâneo | Ipupiara | 4g | Porradeiro | Aquático, DPS | Golpe pesado que enfraquece a defesa do alvo. |
| Sertanejo | Lobisomem do Sertão | 3g | Porradeiro | Metamorfo, DPS | Transformação temporária voltada a ataques contínuos. |
| Sertanejo | Boi Misterioso | 4g | Tank | Encantado, Tank | Investida curta e resistência ao cerco. |

### 3.1 Amazônico — Boto Encantado

**Tradição registrada:** o boto dos rios amazônicos assume forma humana, frequenta festas e usa chapéu para esconder o orifício no alto da cabeça. A Fundaj registra essa associação entre animal, transformação e personagem dos bailes. [Fundaj — Boto](https://pesquisaescolar.fundaj.gov.br/pt-br/artigo/boto/).

**Enquadramento:** Amazônico pelo vínculo com os rios e comunidades amazônicas. A presença de festas não o torna automaticamente Urbano: a transformação do animal fluvial é essencial à narrativa. Associação regional bem sustentada.

**Adaptação — Encanto da Vazante:** ao conjurar, assume brevemente a forma de boto, produz uma onda que concede escudo a até dois aliados próximos e retorna à forma humana. Na primeira versão, a transformação seria visual, preservando a posição no tabuleiro.

**Visual e diferenciação:** alternância entre figura de chapéu claro e boto rosado. Suporte de escudos e transformação, em vez de repetir apenas a cura do Guaraná e da Vitória-régia. Não reaplicar escudos infinitamente por acúmulo.

### 3.2 Amazônico — Capelobo

**Tradição registrada:** narrativas do Pará e do Maranhão descrevem uma criatura feroz com traços humanos e animais; sua forma varia. A referência consultada reúne versões e uma descrição publicada por Fróis Abreu. [Portal São Francisco — Capelobo](https://www.portalsaofrancisco.com.br/folclore/capelobo/).

**Enquadramento:** Amazônico, adotando a vertente paraense e florestal. Não implica que todo o Maranhão seja Amazônia nem que a personagem tenha uma anatomia única.

**Adaptação — Abraço Predatório:** golpeia o alvo atual e recupera parte da vida conforme o dano efetivamente causado. A cura ocorre uma vez por conjuração, sem execução automática.

**Visual e diferenciação:** corpo robusto, focinho alongado e braços desproporcionais; essa combinação é uma escolha artística entre variantes. Seria um Porradeiro de pressão e sustentação, distinguindo-se do papel defensivo de Mapinguari.

### 3.3 Caatinga — Caboclo d'Água do São Francisco

**Tradição registrada:** o Caboclo d'Água integra o imaginário do São Francisco e aparece em narrativas sobre pescadores, peixes e embarcações. Relatos associados a Juazeiro também tratam do Negro d'Água; os nomes e suas relações variam entre fontes. [IEPHA-MG — Inventário Cultural do São Francisco](https://www.iepha.mg.gov.br/images/com_arismartbook/download/8/Inventario%20Cultural%20do%20Sao%20Francisco.pdf), [iBahia — lendas do Vale do São Francisco](https://www.ibahia.com/interior-da-bahia/dia-do-saci-conheca-as-lendas-do-vale-do-sao-francisco-330106).

**Enquadramento:** Caatinga por um recorte explícito do trecho de Juazeiro/Petrolina e de sua cultura ribeirinha no semiárido. É uma escolha regional de design, não uma alegação de que a personagem existe apenas nesse bioma. Ser aquático não o obriga a ser Pantaneiro ou Litorâneo.

**Adaptação — Remanso Revolto:** renova um escudo próprio e projeta uma onda curta que causa pouco dano e interrompe o alvo à frente.

**Visual e diferenciação:** corpo compacto e robusto, pele com aparência molhada e uma correnteza envolvendo os braços. Acrescenta um tanque lendário de custo intermediário à Caatinga e uma ligação com a classe Aquático. Manter a versão regional escolhida identificada no bestiário, sem fundir todas as variantes do Caboclo e do Negro d'Água como se fossem idênticas.

### 3.4 Caatinga — Cabra Cabriola

**Tradição registrada:** cabra monstruosa usada em narrativas de medo e advertência, com circulação no Nordeste e raízes portuguesas. Sua presença no folclore nordestino aparece em pesquisa sobre a obra de Lourdes Ramalho. [Estudo sobre a Cabra Cabriola](https://www.editorarealize.com.br/artigo/visualizar/718), [UFBA — Apontamentos de folclore](https://repositorio.ufba.br/bitstream/ufba/459/1/apontamentos%20de%20folclore.pdf).

**Enquadramento:** Caatinga é uma **adaptação temática**, escolhendo uma ambientação sertaneja de semiárido. A documentação regional consultada não prova exclusividade da lenda na Caatinga. Certeza de encaixe menor que a de uma narrativa ligada a uma localidade específica; apresentar essa distinção no bestiário.

**Adaptação — Cabeçada Cabriola:** atinge o adversário próximo e ganha um reforço temporário nos ataques seguintes. A versão inicial dispensa saltos longos ou mudança de casa.

**Visual e diferenciação:** cabra de chifres retorcidos, olhos luminosos e postura inquieta; detalhes visuais são interpretação artística. Oferece dano corpo a corpo de custo 2, ampliando as escolhas além de defesa e aves. Alternativa possível: Sertanejo, caso o projeto prefira enfatizar a tradição oral em vez da ambientação ecológica; a recomendação principal desta ficha permanece Caatinga.

### 3.5 Cerrado — Pai do Mato

**Tradição registrada:** uma versão divulgada em Goiás apresenta um habitante peludo das matas que protege os animais contra as pessoas. Existem outras variantes regionais. [Só História — Pai do Mato](https://www.sohistoria.com.br/lendasemitos/mato/).

**Enquadramento:** Cerrado, adotando a versão goiana e a paisagem de suas matas. Associação cultural regional, não exclusividade. Algumas tradições aproximam nomes como Pai do Mato e Pé-de-Garrafa; a nova unidade só faz sentido se preservar a versão protetora descrita aqui, em vez de duplicar a entidade já cadastrada.

**Adaptação — Guarda do Mato:** recebe um escudo e protege com um escudo menor o aliado adjacente com menor proporção de vida.

**Visual e diferenciação:** figura peluda de postura protetora, mãos grandes e vegetação aderida ao corpo. Tanque de proteção compartilhada, com presença distinta dos tanques vegetais. Preenche um custo intermediário no Cerrado e cria uma ponte defensiva entre suas peças.

### 3.6 Cerrado — Boitatá

**Tradição registrada:** personagem com múltiplas formas, frequentemente representado como serpente ou clarão de fogo. Há versões relacionadas à proteção dos campos contra queimadas; a MultiRio também registra o motivo de um rastro de fogo em campos e cerrados. [MultiRio — Boitatá](https://multi.rio/index.php/conteudo-geral/13060-boitat%C3%A1), [UOL Educação — variantes do Boitatá](https://educacao.uol.com.br/disciplinas/cultura-brasileira/boitata-cobra-de-fogo-ou-alma-penada.htm).

**Enquadramento:** Cerrado por **adaptação temática fundamentada nos campos e no fogo**, não por suposta origem exclusiva no bioma. A versão adotada será a de guardião dos campos.

**Adaptação — Rastro de Brasa:** sinaliza uma faixa estreita e causa dano mágico por um período curto aos adversários nela presentes. A faixa não deve cobrir todo o tabuleiro nem persistir após o round.

**Visual e diferenciação:** serpente de luz cujo corpo desenha o trajeto da habilidade. Fornece dano mágico de área ao Cerrado; evitar outra cobra de constrição para não repetir Mboi-Guaçu, ou apenas uma grande serpente tanque como Boiúna.

### 3.7 Pantaneiro — Mãozão

**Tradição registrada:** o material educativo da Ecoa reúne narrativas pantaneiras e descreve uma variante de grande criatura peluda cujo toque na cabeça desorienta a pessoa. O próprio texto ressalta a diversidade de descrições. [Ecoa — Pantanal: mundo das águas, seção Lendas e mitos, página 21 do PDF](https://ecoa.org.br/wp-content/uploads/2016/01/Caderno-do-Aluno-Pantanal-mundo-das-%C3%A1guas-ecoa.pdf#page=21).

**Enquadramento:** Pantaneiro pela documentação regional direta. Escolher uma variante na arte e no texto, sem apresentá-la como forma universal.

**Adaptação — Palmada do Desvio:** causa dano baixo e atordoa brevemente um único adversário próximo. A desorientação da lenda inspira o efeito; inicialmente não seria necessário criar uma IA de confusão.

**Visual e diferenciação:** grande silhueta peluda, mão desproporcional e rosto obscurecido. Atua como tanque de interrupção pontual; difere do controle de área do Minhocão. Não permitir sucessivos atordoamentos sem intervalo de reação.

### 3.8 Pantaneiro — Anta Bondosa

**Tradição registrada:** o mesmo material da Ecoa apresenta uma criatura sobrenatural protetora de crianças perdidas no Pantanal, com um aspecto também ambivalente. [Ecoa — Lendas e mitos](https://ecoa.org.br/wp-content/uploads/2016/01/Caderno-do-Aluno-Pantanal-mundo-das-%C3%A1guas-ecoa.pdf#page=21).

**Enquadramento:** Pantaneiro pela associação explícita na fonte. Trata-se da personagem encantada, não apenas de cadastrar a espécie animal anta.

**Adaptação — Caminho de Volta:** concede um pequeno escudo ao aliado próximo mais ferido e, após um intervalo curto, cura esse mesmo aliado caso ainda esteja vivo.

**Visual e diferenciação:** anta espectral de movimentos calmos, com pegadas luminosas. O socorro em duas etapas cria uma identidade diferente da cura de múltiplos aliados do Aguapé. Dimensionar a cura considerando os bônus de Pantaneiro, Encantado e Suporte; não acrescentar ressurreição ao conceito inicial.

### 3.9 Mata Atlântica — Saci-Pererê

**Tradição registrada:** personagem travesso de ampla circulação nacional. Para esta adaptação, o recorte é a tradição caipira do Vale do Paraíba: São Luiz do Paraitinga reconheceu sua Festa do Saci como patrimônio cultural municipal. A MultiRio apresenta seu caráter de desorganizador da ordem. [Prefeitura de São Luiz do Paraitinga — Festa do Saci](https://www.saoluizdoparaitinga.sp.gov.br/leis/leis-municipais/lei-municipal-n-2459-de-2024), [MultiRio — Saci](https://www.multirio.rj.gov.br/index.php?Itemid=115&id=1238&option=com_content&view=article).

**Enquadramento:** Mata Atlântica pela versão local escolhida, ligada à paisagem do Vale do Paraíba/Serra do Mar. Isso não define o berço histórico único do Saci nem elimina versões em outras regiões.

**Adaptação — Redemoinho Travesso:** cria uma pequena área de vento que desacelera inimigos próximos e concede um escudo curto a um aliado dentro dela.

**Visual e diferenciação:** uma perna, carapuça e vento espiralado. Suporte de proteção e perturbação, com dano baixo. Sem roubar permanentemente unidades, itens ou ouro. A habilidade de vento é uma elaboração de jogo, não uma consequência da classificação regional.

### 3.10 Mata Atlântica — Curupira

**Tradição registrada:** guardião da floresta e dos animais, associado a pegadas que confundem perseguidores. O Instituto de Pesquisas Ambientais de São Paulo documenta sua presença cultural no estado e no Horto Florestal. [IPA-SP — Curupira e proteção das florestas](https://www.infraestruturameioambiente.sp.gov.br/ipa/2024/07/no-dia-de-protecao-as-florestas-relembre-a-saga-do-curupira-no-estado-de-sao-paulo/).

**Enquadramento:** Mata Atlântica pela versão paulista adotada. Também poderia receber uma versão Amazônica, mas esta proposta escolhe uma origem única e evita concentrar mais unidades na maior origem do elenco.

**Adaptação — Pegadas ao Contrário:** marca uma pequena área diante dos aliados; os primeiros inimigos que a atravessam recebem lentidão forte e breve. Não mudar casas nem inverter controles na primeira implementação.

**Visual e diferenciação:** pés voltados para trás, cabelos vivos e trilhas de pegadas acesas. Valor concentrado na proteção do posicionamento, diferenciando-o de Caapora e dos tanques Protetores da Mata. A distribuição cultural ampla não deve ser apresentada como exclusividade paulista.

### 3.11 Litorâneo — João Galafuz

**Tradição registrada:** uma aparição luminosa do mar, associada a tempestades e naufrágios, com registros ligados a pescadores de Pernambuco, inclusive Itamaracá. A síntese consultada remete ao Dicionário do Folclore Brasileiro de Câmara Cascudo. [João Galafuz — síntese e referência bibliográfica](https://pt.wikipedia.org/wiki/Jo%C3%A3o_Galafuz).

**Enquadramento:** Litorâneo porque mar, ondas e navegação são parte central da narrativa, não apenas porque a história é contada em uma cidade costeira.

**Adaptação — Aviso de Tempestade:** um clarão marca a posição do alvo e, após um aviso curto, produz uma descarga de dano mágico naquela pequena área. Não acompanha indefinidamente o alvo depois de marcar o chão.

**Visual e diferenciação:** pequena silhueta de luz multicolorida sobre espuma escura. Conjurador acessível para ampliar opções mágicas de baixo custo. **Qualidade documental a aprofundar:** nesta pesquisa, o registro foi consultado por uma síntese secundária; confirmar diretamente o verbete citado antes de redigir o bestiário definitivo.

### 3.12 Litorâneo — Ipupiara

**Tradição registrada:** criatura aquática associada à narrativa de uma aparição na praia de São Vicente em 1564. A prefeitura utiliza essa história em uma ação educativa sobre as lendas locais. Isso atesta a circulação da narrativa, não a existência de um monstro. [Prefeitura de São Vicente — lenda do Ipupiara](https://www.saovicente.sp.gov.br/informacao/filme-produzido-por-alunos-da-amei-duque-de-caxias-retrata-lendas-de-sao-vicente).

**Enquadramento:** Litorâneo por uma associação direta com a praia e o mar na versão vicentina.

**Adaptação — Peso da Arrebentação:** golpeia o inimigo próximo, causa dano físico e reduz temporariamente sua armadura. Uma eventual investida viria depois, caso a movimentação esteja estável.

**Visual e diferenciação:** corpo marinho robusto, membros largos e silhueta parcialmente humanoide; aparência a desenvolver como interpretação artística. Porradeiro aquático para pressionar a frente inimiga, sem repetir uma serpente ou a cura de Mãe-D'Água.

### 3.13 Sertanejo — Lobisomem do Sertão

**Tradição registrada:** o lobisomem circula em muitas regiões e países. O recorte sertanejo tem apoio em estudos de narrativas de cordel, incluindo uma história ambientada em Lavras da Mangabeira, no Sertão do Cariri. [Estudo — A monstruosidade na Literatura de Cordel](https://www.scielo.br/j/gal/a/RrXwbn4LF6CRGKdQBH7bWgG/?lang=pt).

**Enquadramento:** Sertanejo por uma versão ligada ao cordel e ao interior. O complemento “do Sertão” é a identificação editorial da versão proposta, não o nome de uma espécie folclórica universal. Não copiar trama ou caracterização particular de um cordel contemporâneo.

**Adaptação — Noite de Transformação:** assume forma lupina por um intervalo limitado e ganha velocidade de ataque e recuperação de vida ao acertar ataques. A transformação se encerra com o round.

**Visual e diferenciação:** transição legível entre viajante do interior e criatura lupina. Porradeiro de dano contínuo, para se distinguir do Assassino Pé-de-Garrafa. A inclusão depende da decisão sobre a identidade exclusiva de Sertanejo descrita na seção 5.

### 3.14 Sertanejo — Boi Misterioso

**Tradição registrada:** personagem do romance de cordel História do Boi Misterioso, de Leandro Gomes de Barros, inserido no ciclo de narrativas do gado e dos vaqueiros. A UFS analisa a relação entre histórico e mítico nessa obra; a UFCG contextualiza o cenário de fazendas e sertões. **É uma referência de literatura popular com autoria identificada.** [UFS — estudo do cordel](https://ri.ufs.br/handle/riufs/12362), [UFCG — contexto do Boi Misterioso](https://www.ufcg.edu.br/mobile/noticias/mostra_noticia.php?codigo=21290).

**Enquadramento:** Sertanejo pelo vínculo central com o gado, os vaqueiros e o cordel; não é necessário transformá-lo em fauna específica da Caatinga.

**Adaptação — Investida Indomável:** recebe escudo e desfere uma investida curta no adversário à frente, interrompendo-o. A versão inicial pode representar o avanço apenas na animação, sem trocar a célula lógica.

**Visual e diferenciação:** boi imponente, chifres bem definidos e poeira acompanhando os movimentos. Tanque para sustentar uma futura composição sertaneja. Não confundir com Boitatá nem com o boi de outras tradições, como o Bumba Meu Boi.

## 4. Distribuição recomendada e ordem de estudo

O levantamento reúne **21 propostas ainda não implementadas**: 14 novas candidatas e as sete da pesquisa anterior. A distribuição sugerida é de duas para cada origem não urbana, com uma terceira opção em Sertanejo (Chupa-Cabra, reserva), e seis em Urbano.

### Primeiro conjunto para uma futura prototipagem

Selecionar uma candidata por campanha oferece diversidade sem adicionar as 14 de uma vez.

| Origem | Primeira candidata | Motivo | Alternativa |
| --- | --- | --- | --- |
| Cerrado | Pai do Mato | Versão goiana e tanque protetor de custo intermediário. | Boitatá para priorizar dano mágico. |
| Caatinga | Caboclo d'Água do São Francisco | Recorte regional explícito e ligação com Aquático. | Cabra Cabriola para priorizar dano barato, com vínculo temático menos específico. |
| Pantaneiro | Mãozão | Registro regional direto e controle de alvo único. | Anta Bondosa para priorizar suporte protetor. |
| Mata Atlântica | Saci-Pererê | Personagem reconhecível com recorte local e função acessível. | Curupira para priorizar proteção de posicionamento. |
| Litorâneo | Ipupiara | Narrativa costeira localizada e documentada por fonte municipal. | João Galafuz para priorizar magia barata, após aprofundar a fonte. |
| Amazônico | Boto Encantado | Identidade de transformação e função de suporte; Amazônico já tem a maior variedade. | Capelobo para uma opção ofensiva. |

**Sertanejo:** estudar Lobisomem e Boi Misterioso após decidir se a origem continuará exclusiva de Pé-de-Garrafa. Chupa-Cabra fica atrás dessas duas opções por ter associação cultural menos específica.

**Urbano:** manter Loira do Banheiro como principal candidata para a lacuna de custo 3, mas fora do primeiro conjunto voltado às demais origens. Não há necessidade de incluir todas as seis urbanas.

## 5. Decisões que afetam o encaixe no jogo

### Sertanejo já tem uma regra especial

Hoje apenas Pé-de-Garrafa pertence a Sertanejo. O efeito ativa com uma unidade: resistência adicional quando a vida está baixa. Incluir personagens de custo 3 ou 4 permitiria acessar essa origem antes da peça de custo 5 e mudaria sua identidade exclusiva.

**Recomendação:** tratar Sertanejo como futura expansão de sistema, com uma decisão explícita entre preservar a exclusividade ou criar uma origem coletiva. Não escolher novos patamares ou valores apenas nesta pesquisa. Até essa decisão, Lobisomem, Boi Misterioso e Chupa-Cabra são candidatos documentados, não integrantes aprovados do elenco.

### Possível revisão de uma unidade já existente

**Romãozinho: Pantaneiro atualmente; Cerrado como alternativa a investigar.** A associação de versões da personagem com Goiás é bem documentada, inclusive em material da Editora IFG. Uma versão goiana poderia justificar Cerrado com mais clareza que Pantaneiro. Isso não prova que não existam variantes em outras regiões. [Editora IFG — Lendas de minha terra](https://editora.ifg.edu.br/index.php/editoraifg/catalog/download/58/32/302?inline=1), [Editora Naves — Romãozinho e sua circulação regional](https://editoranaves.com.br/romaozinho/).

Essa revisão é **opcional e não foi aplicada**. Romãozinho também ocupa o último posto da formação inimiga do Pantanal: alterar sua origem isoladamente afetaria sinergias sem necessariamente mudar sua presença na campanha. Seria necessário revisar os dois aspectos em conjunto. A expansão proposta funciona mesmo sem essa troca.

### Compatibilidade e balanceamento

- **Custo e tier:** devem acompanhar um ao outro no protótipo, pois a loja sorteia por tier. Os custos deste documento são sugestões, não preços já configurados.
- **Pool:** as 14 novas candidatas elevariam o catálogo de 45 para 59 unidades, antes de qualquer inclusão da pesquisa anterior. Isso mudaria a chance de encontrar cópias dentro de cada tier, mesmo preservando as probabilidades dos tiers.
- **Campanhas:** origem, região cultural e formação inimiga são conceitos distintos. A tabela de candidatas não substitui as listas de inimigos nem altera os chefes atuais.
- **Classes:** todas as fichas usam etiquetas já existentes. Não foi proposta uma nova origem ou uma classe adicional.
- **Efeitos conhecidos:** dano, cura, escudo, lentidão, atordoamento e redução de armadura têm caminhos existentes no combate, mas ainda precisam de integração e testes por habilidade.
- **Efeitos a desenvolver:** transformação visual, área de pegadas, marca atrasada no chão e interação com deslocamento exigem trabalho próprio; não são implementados apenas preenchendo os atributos da unidade.
- **Limites de combate:** efeitos devem terminar com o round; escudos e curas precisam de limites claros; controle repetido deve permitir reação. As sugestões de deslocamento podem começar como animações sem alteração da célula lógica.
- **Sem duplicação acidental:** Pai do Mato/Pé-de-Garrafa, Caboclo/Negro d'Água e Curupira/Caapora exigem versões bem identificadas. Nomes e características podem se aproximar em tradições diferentes; não tratar cada sinônimo como espécie independente.

## 6. Grau de definição da pesquisa

**Definido neste documento:** uma origem principal por candidata; separação entre fonte cultural e proposta de combate; revisão das sete sugestões anteriores; duas novas opções por origem não urbana; justificativas e referências; restrição atual de Sertanejo; prioridades para estudo futuro.

**Ainda em aberto:** seleção final do elenco, números de atributos, balanceamento das habilidades, modelos, animações, textos finais de bestiário e eventual revisão das sinergias ou campanhas. Cabra Cabriola/Caatinga e Chupa-Cabra/Sertanejo são os enquadramentos mais interpretativos; João Galafuz requer aprofundamento da fonte bibliográfica.

As fontes foram consultadas para esta pesquisa em 27/10/2026. Fontes institucionais, acadêmicas e locais foram priorizadas quando disponíveis. As sínteses secundárias utilizadas estão identificadas nas fichas. Nenhuma origem de gameplay deve ser apresentada ao jogador como uma classificação histórica universal dessas tradições.
