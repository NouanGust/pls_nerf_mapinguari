# Controles e impasse entre plantas — 19/10/2026

## HUD e câmera

O botão HUD e a tecla H deixam de recalcular o enquadramento. A câmera mantém distância e deslocamento ao ocultar ou mostrar a interface. Redimensionamento da janela, zoom manual e órbita continuam disponíveis.

## Espaço e foco dos botões

Durante preparação e combate, `main.gd` consome a pressão, a repetição e a soltura de Espaço antes que o evento chegue aos botões. Apenas a primeira pressão pode iniciar a luta. Isso impede repetir a última ação da interface, como rerrolar, comprar XP ou ocultar o HUD.

Enter continua disponível para ativar controles com foco. Nos menus de pausa e resultado, Espaço mantém o comportamento normal de confirmação da interface; não inicia combate por trás desses painéis.

## Unidades imóveis

O monitor de combate reconhece um impasse quando:

- Ambos os times ainda possuem unidades vivas no campo.
- Todos os sobreviventes são unidades imóveis; o banco é ignorado.
- Nenhum par de adversários está ao alcance de ataque em qualquer direção.
- Não há conjuração nem queimadura em andamento nos sobreviventes.

Se a condição permanecer por três segundos de tempo de jogo, encerra como empate antecipado. O relatório mostra “Unidades imóveis sem alcance entre os times”. Aplicam-se as mesmas consequências do empate por tempo: metade do dano ao jogador e metade da recompensa de vitória, com a regra de arredondamento existente. A pausa também pausa a contagem.

Se apenas um lado alcançar o outro, a luta continua. Havendo unidades móveis, a resolução permanece normal. O alcance e a imobilidade das plantas não mudam. O limite geral de 60 segundos continua cobrindo outros impasses, como cura sustentada entre adversários que conseguem atacar.

O alcance em metros usado por seleção de alvo, execução do ataque e detecção do impasse foi centralizado em `BaseUnit3D.get_attack_range_meters()`. O período de tolerância pode ser ajustado em `stationary_stalemate_seconds`, no script principal.

Alterações revisadas por leitura do código; sem execução de partidas ou testes na engine nesta rodada.
