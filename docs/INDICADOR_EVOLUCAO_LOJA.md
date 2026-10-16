# Indicador de evolução na loja

Quando uma oferta completa um trio de cópias de uma estrela, a carta recebe uma borda luminosa pulsante e uma faixa de brilho suave. O texto acima do retrato indica a estrela final, incluindo evoluções em cadeia:

- **Dourado:** compra completa 2 estrelas.
- **Violeta:** compra completa uma cadeia até 3 estrelas.
- **Ciano:** compra completa uma cadeia até 4 estrelas.

O cálculo inclui campo, banco e unidades derrotadas no combate atual, que serão restauradas na preparação. Unidades vendidas ou consumidas aguardando liberação são ignoradas. Trios já pendentes durante a batalha são contabilizados antes da simulação da compra: uma evolução já garantida não acende uma oferta desnecessária.

Durante o combate, o tooltip informa que a evolução acontece no início do próximo round. O indicador representa a combinação possível; as regras de ouro, espaço no banco e posicionamento continuam controlando a compra. Nenhuma evolução é antecipada pelo indicador.

O estado visual é atualizado nas compras, vendas, posicionamentos, reembolsos de arraste, mudanças de round e atualização da loja. Cartas vendidas ou vazias perdem o efeito. Cada carta possui seu próprio material; o shader não substitui o material do retrato e acompanha a transparência do HUD.

## Arquivos

- `Assets/Shaders/shop_upgrade_hint.gdshader`: borda, halo, pulso e faixa de brilho.
- `Scripts/UI/unit_card.gd`: material individual, cor, estrelas e tooltip.
- `Scripts/UI/shop_ui.gd`: simulação de evolução e atualização das ofertas.
- `Scripts/main.gd`: contagem das unidades possuídas.

Revisão por leitura do código; efeito ainda não executado no Godot nesta alteração.
