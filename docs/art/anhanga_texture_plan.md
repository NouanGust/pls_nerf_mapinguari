# Anhangá — plano de textura para a alpha

**Estado:** ferramentas desktop Blockbench conectadas em 20/10/2026; script de produção preparado em `tools/art/texture_anhanga.js`, com sintaxe verificada. A aplicação no modelo e sua validação visual ainda dependem da execução pelo agente responsável pela sessão compartilhada.

## Implementação para o primeiro modelo alpha

O script cria um atlas opaco de 256 × 256 pixels com dimensões UV lógicas também de 256 × 256. Usa regiões compartilhadas de material, com microvariação de apenas 2–4 níveis de RGB nas superfícies maiores. Olhos, marca frontal, nariz e boca são cores uniformes. A marca é recortada pela geometria do modelo, e não por transparência.

Cada face recebe projeção planar em base ortonormal calculada a partir de seus vértices. Isso preserva as proporções das faces planas, em vez de aplicar um retângulo completo a partes de tamanhos diferentes. A densidade inicial executável é **4 pixels por unidade Blockbench / 64 pixels por unidade Godot**, reduzida por igual dentro de cada categoria caso a maior face não caiba. Pelo base e sombra compartilham a mesma densidade. O retorno do script registra densidade por categoria, amostras de dimensões, limites, variação de densidade nas arestas e desvio de planaridade.

As reservas abaixo substituem as reservas exploratórias posteriores deste documento para a implementação atual:

| Material / prefixo de mesh | Retângulo do atlas em pixels |
| --- | --- |
| `fur_` | X 0–160, Y 0–144 |
| Pelo inferior, normal Y < −0,35 | X 0–128, Y 144–256 |
| `antler_` | X 160–256, Y 0–128 |
| `antler_tip_` | X 128–192, Y 144–200 |
| `hoof_` | X 192–256, Y 128–192 |
| `inner_ear_` | X 128–192, Y 200–256 |
| `nose_` | X 192–224, Y 192–224 |
| `eye_` | X 224–256, Y 192–224 |
| `mark_` | X 192–224, Y 224–256 |
| `mouth_` | X 224–256, Y 224–256 |

Todas as coordenadas ficam pelo menos cinco pixels dentro da região de material. Compartilhar regiões é intencional; não existe detalhe assimétrico único sobreposto. A sombra inferior foi suavizada para `#C5C0C1` e os olhos usam âmbar `#F29A35`, mantendo leitura sem emissividade. Ainda é necessário conferir o resultado na câmera real do jogo.

## Referência e leitura visual

Referência inspecionada: `Assets/Units_teste/Anhangá.png`. O retrato apresenta cervo de pelo branco quente, sombras cinza malva, galhadas marrons com pontas marfim, olhos vermelho/âmbar, orelhas com interior terracota, focinho escuro e marca dourada na testa. Preservar esses sinais em massas grandes; simplificar os fios de pelo e as fissuras da galhada em poucos agrupamentos pintados. A aura do retrato não deve virar transparência sobre todo o corpo.

O recurso `resources/units/anhanga.tres` identifica um guardião da mata com habilidade “Rugido da Floresta”. Pintar também interior da boca e parte inferior da mandíbula, visíveis no rugido. A marca frontal vem desta referência artística específica; não representa uma afirmação sobre uma iconografia tradicional.

## Material e orçamento propostos

- Destino: Godot 4.6, PC, conforme projeto atual; modelo low poly visto de cima e de três quartos, até 1.500 triângulos. Plano geral em `docs/art/alpha_blockbench_plan.md`.
- Um atlas opaco de albedo, PNG 256 × 256, e um material principal `M_Anhanga`. Manter `albedo_color` branco para preservar as cores pintadas.
- Iluminação dinâmica sobre faces facetadas; metallic 0 e roughness inicial 0,88. Evitar sombras direcionais fortes pintadas, pois a unidade gira.
- Sem normal map, displacement, pelos transparentes ou camadas de pelagem na alpha.
- Emissão opcional: mapa RGB 256 × 256 com fundo preto e regiões dos olhos/marca frontal, alinhado ao mesmo UV. É uma etapa adicional, não uma textura já entregue. Manter reconhecimento por cor quando emissão/glow estiverem desligados.
- Filtragem inicial linear com mipmaps; verificar bleed e cintilação na distância real da câmera. A opção de nearest existente no projeto é para CanvasItem e não estabelece a filtragem de materiais 3D.

As cores abaixo são escolhas de direção de arte por inspeção visual, não amostras medidas do arquivo.

| Uso | Cor |
| --- | --- |
| Pelo base | `#DDD8C9` |
| Pelo iluminado | `#F5EDD8` |
| Sombra suave de pelo | `#A5A0A3` |
| Sombra profunda sob ventre/mandíbula | `#74747E` |
| Galhada base | `#785142` |
| Galhada clara | `#B48B63` |
| Pontas da galhada | `#E7D5AC` |
| Interior de orelha | `#A94E43` |
| Nariz e casco | `#34262F` |
| Boca interna | `#4A2029` |
| Língua | `#A95462` |
| Olho externo | `#E94A29` |
| Olho central e marca frontal | `#FFD473` |

## Plano de UV

Atlas único, sem repetição além das bordas. Escala combinada: **16 unidades Blockbench = 1 unidade Godot**; comprimento até 1,65 e altura total até 1,9 unidades Godot, incluindo galhada. Estabelecer essa escala antes do unwrap. Usar **80 pixels por unidade Godot** (5 px/unidade Blockbench) como ponto de partida para superfícies com detalhes; até 120 px/unidade Godot para a cabeça. Esses valores são metas a ajustar uniformemente após medir área e empacotamento, não densidades verificadas.

Reservas iniciais no atlas abaixo usam intervalos `[mínimo, máximo)` em pixels. Não são UVs prontos nem garantem que o unwrap caiba. Reempacotar conforme as áreas reais, preservando proporções, em vez de comprimir um eixo.

| Região reservada | Conteúdo |
| --- | --- |
| X 0–128, Y 0–128 | Tronco, peito e pescoço |
| X 128–256, Y 0–128 | Cabeça, testa e orelhas |
| X 0–128, Y 128–224 | Pernas e cascos, pares reutilizados |
| X 128–224, Y 128–224 | Galhadas, tiras proporcionais |
| X 224–256, Y 128–224 | Swatches uniformes de apoio |
| X 0–128, Y 224–256 | Cauda e faces inferiores |
| X 128–256, Y 224–256 | Mandíbula, boca e língua |

Regras de execução:

1. Confirmar dimensões UV lógicas e bitmap real. Se forem 256 × 256, uma unidade UV corresponde a um pixel; não assumir isso antes da inspeção.
2. Reservar no mínimo quatro pixels de extrusão ao redor de cada ilha, mantendo oito pixels entre conteúdos distintos. Revisar na distância de jogo: padding não elimina sozinho o bleed em todos os níveis de mip.
3. Espelhar apenas superfícies simétricas: pares de pernas e orelhas e lados correspondentes do tronco. Testa e sua marca ficam numa ilha própria, sem costura central.
4. Manter costuras do tronco na parte inferior, das pernas na parte interna e do pescoço atrás. Pintar superfícies reveladas durante caminhada, ataque, rugido e queda.
5. Galhadas usam tiras proporcionais para faces laterais e regiões próprias para pontas/cortes. Não esticar o mesmo retângulo cheio sobre faces com comprimentos diferentes.
6. Swatches uniformes podem usar UVs pequenos ou coincidentes intencionalmente. Não aplicar esse atalho em olhos, marca frontal, estrias ou qualquer canal com detalhes.
7. Pelagem usa grupos largos de dois ou três tons acompanhando o volume, com detalhes mais finos apenas no focinho e peito. Olhos precisam permanecer legíveis sem depender de bloom.

## Integração que precisa ser verificada

`Scripts/Units/unit_visual.gd` duplica materiais `StandardMaterial3D` para flashes de dano e evolução; no caminho humanoide atual, a seleção depende do nome `M_Main` e aplica cor de equipe. A integração do novo modelo deve preservar o albedo branco do Anhangá e escolher explicitamente quais materiais recebem os efeitos. `Scripts/Units/biodiversity_models.gd` ainda não registra Anhangá como espécie. O plano de textura, isoladamente, não conecta o personagem ao jogo.

O ambiente em `new_environment.tres` possui luz ambiente forte e glow. Comparar a textura sob esse ambiente e sob iluminação neutra para evitar que o branco perca volume e que os olhos virem manchas saturadas.

## Validação pendente

- Inspecionar UVs e dimensões efetivas de cada textura no Blockbench; medir densidade em ambos os eixos para tronco, cabeça, perna e galhada.
- Aplicar checker temporário; comparar quadrados em superfícies largas, finas, lados e pontas. Registrar diferenças intencionais da cabeça.
- Inspecionar atlas e modelo em frente, lados, costas e três quartos; repetir com mandíbula aberta e pernas afastadas.
- Conferir bordas das ilhas com mipmaps e silhueta na câmera de combate; não avaliar apenas com zoom.
- Exportar fonte editável e runtime pelo fluxo disponível do Blockbench; inspecionar material, texturas e UVs após importação no Godot.
- Confirmar efeitos de dano/evolução e várias unidades simultâneas. Registrar contagem real de materiais/superfícies: um atlas não garante, sozinho, uma única chamada de desenho.

**Entregas futuras previstas:** atlas de albedo, mapa de emissão se adotado, UVs aplicados na fonte `.bbmodel`, material no runtime e imagens de verificação. Nenhuma dessas entregas foi produzida nesta etapa.
