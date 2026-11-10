# Comadre Fulozinha — Ficha de design (Design Brief)

## Frase de silhueta
"Caboquinha ágil de baixa estatura quase totalmente envolta por uma enorme cabeleira viva em forma de manto drapeado até os joelhos, empunhando um chicote de cipó e urtiga, com postura dinâmica de espreita."

## Três formas-base
1. **Forma primária (massa dominante):** Sino/cone invertido e manto drapeado formado pela vasta cabeleira negra que desce pelas costas e flancos, cobrindo o corpo esguio e descendo até a altura dos joelhos/pernas.
2. **Forma secundária (o que quebra a silhueta):** Curva orgânica e dinâmica do chicote longo de cipó e talos de urtiga serpenteando a partir de sua mão direita, contrastando com galhos espetados de urtiga e cipós entrelaçados no topo da cabeça.
3. **Forma terciária (detalhe de leitura):** Olhos escuros profundos e faiscantes ("cor de jabuticaba"), pequenas flores silvestres miúdas (*fulô*) pontilhadas na densidade do cabelo e pés ágeis descalços firmados no solo.

## Proporção
- **Nº de cabeças:** 5,8 cabeças (proporção juvenil canônica de menina/caboquinha de 10 a 12 anos, ágil e franzina).
- **Altura em metros:** 1,35 m (do solo ao topo da cabeça; com cipós/folhagens superiores atinge ~1,42 m).
- **Relação com a unidade-âncora (Mãe d'Água):** Notavelmente mais baixa e compacta que a Mãe d'Água (1,82 m no topo do cocar), gerando contraste visual imediato no tabuleiro entre uma guardiã lendária soberana/esguia e uma entidade ágil, espreitante e veloz.

## Paleta (com hex)
- **Cor dominante (Cabeleira viva / Manto vegetal):** `#161314` (preto profundo com nuances de terra úmida e fumo de corda) — origem no texto: *"imensa cabeleira negra... cobrindo a nudez"*.
- **Cor secundária (Pele cabocla acobreada/morena):** `#7E482B` (tom terroso bronze/acobreado, sombra `#542E1A`) — origem: *"jovem cabocla ou menina... pele e olhos cor de jabuticaba"*.
- **Cor de acento 1 (Urtigas e cipós):** `#2F5227` (verde floresta escuro com talos `#4B3621` de cipó seco) — origem: *"folhas denteadas de urtiga, cipós retorcidos"*.
- **Cor de acento 2 (Flores silvestres - Fulô):** `#D48B28` e `#E0C068` (amarelo dourado e âmbar silvestre das pequenas flores) — origem: *"pequenas flores silvestres (fulô)"*.
- **Acento místico (Olhos de jabuticaba):** `#0C080E` com brilho especular vivo `#A8E6CF` (faiscante na penumbra).
- **Emissivo (Açoite da floresta / Magia de conjuração):** `#5AE38C` (verde-folha bioluminescente sutil nas pontas das urtigas e no ápice do chicote quando conjura a habilidade).

## Materiais
| Parte | Material | roughness | metallic | Observação |
|---|---|---|---|---|
| Corpo / Pele | `Fulozinha_PBR` | 0.55 | 0.0 | Pele cabocla macia, levemente úmida de suor/orvalho da mata |
| Cabelo Manto | `Fulozinha_PBR` | 0.70 | 0.0 | Fios espessos e emaranhados formando camadas volumosas |
| Urtigas & Cipós | `Fulozinha_PBR` | 0.40 | 0.0 | Brilho ceroso de seiva nas folhas denteadas de urtiga |
| Flores silvestres | `Fulozinha_PBR` | 0.60 | 0.0 | Pétalas aveludadas pontuando as mechas |
| Chicote | `Fulozinha_PBR` | 0.45 | 0.0 | Cipó fibroso torcido e talos com espinhos urticantes |

## Anatomia e elementos
- **Tronco e membros:** Busto e pernas franzinos de jovem cabocla (base derivada de `GEO-body_female_stylized`, redimensionada e ajustada para anatomia juvenil esguia de 1,35 m), pés descalços com firmeza no chão.
- **Rosto:** Traços caboclos delicados, maçãs do rosto marcadas, olhos grandes e escuros com brilho penetrante, expressão que mescla travessura e severidade vigilante.
- **Cabeleira viva:** Volume contínuo que nasce do couro cabeludo, cai pelas costas até a curva das pernas e desce pelas laterais e frente do torso, vestindo o corpo sem necessidade de roupas convencionais.
- **Folhagem integrada:** Ramos de urtiga com folhas denteadas e brotos de flores silvestres embutidos fisicamente na malha do cabelo.
- **Açoite / Chicote:** Cordão trançado de cipó com nós e espinhos de urtiga, com extensão em curva de 1,1 m a partir da mão direita.

## Transformações e estados
- **Idle:** Postura ágil em semi-agachamento (pronta para saltar), respiração sutil, chicote repousando em curva orgânica rente ao solo, mechas de cabelo ondulando levemente.
- **Attack:** Chicoteio rápido e cortante em arco frontal com o braço direito, impulsionado pelo giro dos quadris, com estalo seco de vento.
- **Stunned:** Recuo brusco, tronco encolhido protegendo-se sob a cabeleira, cabeça inclinada e chicote frouxo no chão.
- **Channel:** Mãos erguidas à frente dos lábios imitando o assobio místico (*"siu, siu..."*), cabelos levantando-se levemente ao redor como cipós vivos.
- **Death:** Desabamento de joelhos, chicote solto da mão, corpo curvando-se para a frente e sendo recoberto e absorvido pela própria cabeleira que pousa no solo.
- **Ability (*Invocação da Floresta / Açoite de Urtiga*):** Salto ou elevação súbita com os braços abertos, chicote girando em espiral acima da cabeça liberando a fúria das urtigas e cipós da mata em área.

## Movimento
- **Vocabulário:** Movimentos rápidos, felinos e imprevisíveis; passadas silenciosas; giros rápidos e espreita rasteira. Em combate, atua como conjuradora à distância mantendo postura vigilante e esquiva.
- **Ritmo:** Pausa atenta seguida de estalo veloz (análogo ao estalo de chicote e ao assobio enganoso que inverte distâncias).

## Elementos secundários
- **Cadeia de mechas de cabelo:** 3 cadeias de bones (esquerda, direita e posterior) para movimentação secundária e drapeado.
- **Cadeia do chicote:** 6 a 8 bones flexíveis para chicoteio dinâmico e pose orgânica.
- **Folhas de urtiga e flores:** Rígidas em relação aos bones do cabelo, acompanhando as deformações das mechas.

## Decisões autorais (precisam de aprovação)
1. **Malha contínua de cabelo estilizado (sem clipagem):**
   - Substituímos mechas avulsas por uma malha contínua e rica de cabelo estilizado (`GEO_Hair`): base anatômica craniana sem aspecto de capacete rígido, franjas estilizadas emoldurando a testa e sobrancelhas, mechas laterais sobre o peito e manto contínuo drapeado pelas costas até a altura das panturrilhas, com vincos/canaletas esculturais e pontas afiladas.
   - Aplicação de verificação espacial geométrica (BVH tree com margem de segurança de 15 mm a 20 mm), garantindo **zero clipagem** com a malha do corpo, braços ou dorso.
2. **Chicote como acessório destacado que ela empunha (`Acessorio_Chicote`):**
   - O chicote foi reestruturado como um objeto acessório/prop independente na coleção `PROPS`, composto por: cabo/empunhadura de madeira e cipó trançado empunhado firmemente pela mão direita, anel de guarda, pomo de amarração, corpo flexível de cipó com nós espinhosos de urtiga e ponta em espiral rente ao solo.
3. **Cobertura corporal pelo próprio manto vivo de cabelo:**
   - Em conformidade com a tradição oral (Câmara Cascudo e relatos paraibanos/pernambucanos), a criatura não usa roupas de tecido, tendo o corpo esguio e ágil velado pela própria cabeleira viva entrelaçada com urtigas e flores silvestres.

## Descartado
- **Asas de fada ou visual élfico ocidental:** Rejeitado terminantemente; trata-se de um espírito caboclo/indígena da floresta, não de folclore celta.
- **Montaria em porco-do-mato ou cachimbo de Caipora:** Descartado; o texto canônico destaca que Fulozinha abomina ser confundida com o Caipora.
- **Roupas de tecido de algodão/vestidos coloniais:** Descartado em favor da cabeleira viva como manto, muito mais potente visual e narrativamente.

