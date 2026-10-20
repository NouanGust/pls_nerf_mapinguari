# Anhangá — plano de rig e animação para a alpha

**Estado em 20/10/2026:** planejamento concluído; rig, keyframes, `.bbmodel` e animações exportadas **ainda não foram produzidos**. As ferramentas Blockbench não estão expostas nesta sessão. Este documento não substitui a entrega do asset.

## Direção e referência local

Usar `Assets/Units_teste/Anhangá.png`: cervídeo branco quadrúpede, pescoço erguido, galhada ampla, olhos incandescentes e presença de guardião. A animação deve transmitir peso e vigilância, preservando a leitura da galhada na câmera do tabuleiro. Ataque corporal é um golpe de cabeça/galhada; não é necessário reproduzir um soco apesar do nome técnico atual do clip.

A produção deverá acontecer pelo Blockbench, usando as skills `blockbench-use` e `blockbench-animation`. Descobrir capacidades e exportadores reais antes de escolher entre grupos rígidos e armature com pesos. A proposta abaixo favorece partes rígidas articuladas para a primeira versão low poly; depende da confirmação de que o caminho disponível exporta hierarquia e animações para Godot.

Contrato compartilhado proposto em `docs/art/alpha_blockbench_plan.md`: Generic Model (`free`, confirmar disponibilidade), 16 unidades Blockbench para 1 unidade Godot, até 1.500 triângulos, atlas de 256 × 256, animação de nós rígidos e ausência de root motion. Conferir escala após exportar; não assumir que o exportador fará essa conversão automaticamente.

## Contrato já existente no jogo

| Fonte | Comportamento observado | Consequência para o asset |
|---|---|---|
| `Scripts/Units/unit_visual.gd` | Busca recursiva de um nó chamado `AnimationPlayer`; nomes de clips fixos | Entregar um único player acessível e os nomes exatos abaixo, sem prefixo de biblioteca |
| `Scenes/Units/unit_visual.tscn` | Instancia `Assets/Models/UAL1_Standard.glb` como `Character` | Anhangá ainda utiliza o personagem compartilhado; exportar um modelo não realiza a seleção por espécie |
| `Scripts/Units/biodiversity_models.gd` | Seleção atual de espécies não inclui `anhanga` | A integração futura precisa de seleção explícita de Anhangá sem trocar os demais personagens |
| `Scripts/Units/base_unit.gd` | Movimento e orientação pertencem ao `CharacterBody3D`; frente é `+Z` | Modelo final: `+Y` para cima, frente `+Z`, chão em `Y = 0`; clips sem deslocamento da raiz no mundo |
| `resources/units/anhanga.tres` | Movimento 180; ataque 0,8/s; corpo a corpo; Rugido da Floresta | Velocidade base real 1,8 unidades/s; intervalo de ataque 1,25 s |
| `unit_visual.gd::update_locomotion` | Playback de caminhada = velocidade / 2, limitado a 0,4–2 | A 1,8 unidades/s, `Walk` toca a 0,9× |
| `unit_visual.gd::play_attack` | Acelera o clip para caber em até 85% do intervalo; não o desacelera | `Punch_Jab` de 0,70 s toca a 1× no Anhangá sem bônus |
| `unit_visual.gd::play_cast` | Ajusta qualquer duração do clip para terminar em 0,5 s | Autorizar o rugido em 0,50 s evita compressão inesperada |
| `base_unit.gd::cast_ability` | Efeito e VFX disparados imediatamente; estado `CASTING` dura 0,5 s | O rugido visual deve ter leitura rápida; duração de debuff de 4 s não é duração da animação |
| `unit_visual.gd::flash_damage` | Só altera temporariamente a cor do material | `Hit` pode ser entregue, mas precisará de despacho próprio para tocar no jogo |
| `unit_visual.gd::_play` | Blend geral de 0,12 s | Inspecionar ataque/rugido com esse blend; poses muito breves podem desaparecer |
| `base_unit.gd::die` | Morte lógica imediata; aguarda duração de `Death01` antes de ocultar/remover | Morte sem loop; pose terminal sustentada até a remoção |

Não colocar tracks de método, dano, deslocamento de personagem ou aplicação do rugido nos clips. O combate já resolve essas ações em código. Um evento de animação adicional duplicaria efeitos.

## Rig proposto

Nomes são proposta de autoria, não ossos existentes. Congelar a hierarquia após o blockout e antes de texturizar/animar.

```text
anhanga_root
└── body
    ├── chest
    │   └── neck
    │       └── head
    │           ├── jaw
    │           ├── ear_l
    │           └── ear_r
    ├── tail
    ├── fore_upper_l
    │   └── fore_lower_l
    │       └── fore_hoof_l
    ├── fore_upper_r
    │   └── fore_lower_r
    │       └── fore_hoof_r
    ├── hind_upper_l
    │   └── hind_lower_l
    │       └── hind_hoof_l
    └── hind_upper_r
        └── hind_lower_r
            └── hind_hoof_r
```

São 21 nós articuláveis incluindo a raiz. Galhada e olhos acompanham `head`, sem articulações próprias. `chest` movimenta pescoço/cabeça; pernas anteriores permanecem em `body`, evitando levantar os cascos durante a respiração. Essa simplificação exige rotação pequena de peito para manter a região do ombro visualmente conectada.

- `anhanga_root`: origem no solo, centro da projeção do corpo; transformação constante em todos os clips.
- `body`: pivô no centro de massa, acima do solo; pode oscilar pouco em Y, inclinar e cair.
- Pernas: pivôs nos ombros/quadris, joelhos/jarretes e cascos; jamais no centro de cada cubo. Reservar sobreposição nas junções rígidas para não abrir frestas.
- `neck`, `head` e `jaw`: pivôs anatômicos; mandíbula com malha separada para o rugido.
- Escala uniforme no asset; evitar animar escala para simular volume corporal, pois pode deformar os filhos.
- Dimensões finais e amplitude das pernas deverão ser validadas contra a célula real. Não tratar os limites de espécies existentes como tamanho obrigatório para a galhada.

## Clips a produzir

Autoria sugerida em 30 fps, tempos em segundos. FPS é uma grade de edição, não garantia de amostragem do exportador.

| Ação artística | Nome exato no Godot atual | Duração | Loop | Poses e leitura |
|---|---|---:|---|---|
| Vigilância/respiração | `Idle` | 2,00 s | Sim | Quatro cascos plantados; peito/pescoço respiram; cabeça observa discretamente; uma orelha reage; cauda curta |
| Caminhada quadrúpede | `Walk` | 0,80 s | Sim | Marcha de quatro apoios com contatos defasados; leve oscilação do corpo; galhada estável e pesada |
| Golpe de galhada | `Punch_Jab` | 0,70 s | Não | Cabeça reage rapidamente para a frente, atinge pose forte cedo e retorna com peso; cascos traseiros sustentam o corpo |
| Rugido da Floresta | `Spell_Simple_Shoot` | 0,50 s | Não | Elevar pescoço, abrir mandíbula, sustentar rugido e relaxar; pernas firmes; cabeça não atravessa o peito |
| Receber impacto | `Hit` | 0,20 s | Não | Recuo curto de cabeça/peito, orelhas para trás; sem deslocar a raiz; integração pendente |
| Morte | `Death01` | 1,20 s | Não | Perda de suporte, flexão das pernas, queda lateral compacta, acomodação da galhada e pose terminal |

Não criar `attack`, `roar` ou `death` como únicos nomes exportados: o runtime busca os nomes da tabela. Um mapa de nomes próprio por espécie é uma melhoria futura possível, não requisito para esta entrega inicial.

### Timing a validar nas poses

**Idle:** 0,00 / 0,50 / 1,00 / 1,50 / 2,00. Respiração pequena, cabeça próxima da pose neutra; início e fim equivalentes e tangentes compatíveis. Orelhas não precisam mudar em todos os marcos.

**Walk:** fases principais em 0,00 / 0,20 / 0,40 / 0,60 / 0,80; intermediárias em 0,10 / 0,30 / 0,50 / 0,70. Ordem inicial proposta de contato: traseira esquerda, dianteira esquerda, traseira direita, dianteira direita, com apoio de cada casco por aproximadamente 65% do ciclo. Ajustar após observar peso e estabilidade; uma simples senoide de pernas não é validação de marcha.

No playback 1×, a referência de deslocamento é 2 unidades/s. Durante um apoio, o casco precisa deslocar-se para trás no espaço local aproximadamente nessa velocidade para compensar o avanço do personagem. Em 0,80 s, a referência percorre 1,60 unidades; isso exige conferir tamanho corporal e amplitude antes de manter esse período. Na velocidade base do Anhangá, o ciclo efetivo dura cerca de 0,889 s. Validar contato em movimento, sem interpretar animação parada como garantia contra deslizamento.

**Punch_Jab:** leitura rápida entre 0,00–0,10; golpe 0,10–0,20; recuperação 0,20–0,70. O dano real acontece na chamada, antes do contato visual. A alpha pode aceitar essa diferença pequena, mas uma sincronização física exata exigiria alteração deliberada do combate. Não prolongar antecipação sem discutir esse atraso visual.

**Spell_Simple_Shoot:** início 0,00; boca/pescoço abertos até 0,10; ápice em 0,20; recuperação 0,33–0,50. A janela de 0,12 s de blend deve ser considerada. O VFX de rugido já existe no gameplay; não incluir duração adicional de partículas no clip.

**Hit:** pico de recuo em torno de 0,067; volta até 0,20. Uso futuro preferencial em camada superior ou como resposta que não cancela ataques, rugidos nem morte. O sistema atual não tem essa camada nem método `play_hit`; não habilitar simplesmente no mesmo player sem definir prioridade.

**Death01:** perda de força até 0,20; pernas dobram 0,20–0,47; corpo apoia 0,47–0,80; acomodação até 1,07; sustentar até 1,20. Deslocar apenas o corpo no espaço local. Preservar chão e evitar que a galhada atravesse o tabuleiro. Os clips de retorno precisam restaurar todos os canais afetados pela morte para que reviver não mantenha pernas dobradas.

## Integração futura, sem alteração nesta etapa

1. Confirmar exportador disponível que preserve animações/hierarquia para Godot; não pressupor que exportação de geometria também exporte clips.
2. Manter fonte editável `.bbmodel` e export runtime validado. Um `.glb` seria o candidato coerente com a cena atual, somente se estiver disponível no caminho real de exportação.
3. Adicionar seleção explícita por `unit_id == "anhanga"` no fluxo visual. Evitar substituir `Character` globalmente.
4. Descobrir o `AnimationPlayer` do Anhangá e conferir todos os cinco nomes obrigatórios. `Hit` é o sexto clip, com disparo ainda pendente.
5. Se usar `_species_model` para armazenar o novo modelo, impedir que a oscilação procedural de `unit_visual.gd::_process` seja somada à caminhada autorada. Hoje ela se aplica a qualquer `_species_model` móvel, mesmo que tenha player.
6. Configurar loops na importação: `Idle`/`Walk` repetem; ataque/rugido/impacto/morte não. A configuração atual não corrige loop em tempo de execução.
7. Preservar materiais/texturas brancos e olhos; o ramo de humanoide recolore `M_Main`, enquanto o de espécie mantém a cor original e duplica materiais para feedback. Verificar flashes e independência entre instâncias.
8. Não aplicar BoneMap humanoide automaticamente ao cervídeo. O teste `tests/unit_visual_smoke.gd` usa Caapora e exige `Hips`; isso continua adequado para aquele personagem, não comprova nem define rig de Anhangá.

## Verificação quando as ferramentas estiverem conectadas

- Conferir capacidades, formato e hierarquia reais antes de gerar keyframes; usar IDs retornados, sem inventá-los.
- Visualizar frente, lado e câmera elevada; percorrer início, extremos e poses intermediárias de todos os clips.
- Inspecionar as duas extremidades dos loops e a velocidade na emenda, contatos de cascos, folgas em juntas, mandíbula, clipping de galhada e chão.
- Exportar e abrir no Godot; conferir nomes, duração, loops, orientação, tamanho e pose inicial. Preview no Blockbench sozinho não certifica o runtime.
- Exercitar transições `Idle → Walk → ataque → Idle`, `Walk → rugido → Idle`, interrupção pela morte e morte seguida de reviver antes de 1,20 s.
- Verificar movimento na velocidade base, sob lentidão e bônus; verificar ataque acelerado.
- Confirmar que dano, mana e debuff continuam ocorrendo uma única vez, que morte remove colisões imediatamente e que reviver restaura pose, materiais e visibilidade.
- Teste existente `unit_visual_smoke.gd`: regressão do personagem compartilhado. Criar posteriormente teste específico de Anhangá quando o asset importado existir, sem repetir a suposição de esqueleto humanoide.

**Validação realizada agora:** leitura do código, cenas, recurso de unidade, testes existentes e inspeção da imagem de referência. Não foram executados testes de animação nem produzido render, pois ainda não há animações autoradas.
