# Splash arts — natureza assombrada

Foram criadas 25 artes individuais para as unidades que não possuíam `icon`. O elenco atual de 45 unidades passa a ter retratos atribuídos.

- Arquivos: `Assets/Units/SplashArts/<unit_id>.png`.
- Formato entregue: PNG quadrado de **1254 × 1254 pixels**, com cenário e fundo opaco.
- Direção: fantasia sombria, terror atmosférico, névoa, texturas naturais e energia sobrenatural relacionada às habilidades.
- Geração: ferramenta integrada **image_gen**, uma geração por unidade.
- Integração: referências `Texture2D` no campo `icon` dos 25 recursos em `resources/units`; os componentes existentes da loja, banco, inspeção e relatório reutilizam esse campo.
- Revisão: imagens inspecionadas visualmente durante a geração; dimensões e atribuições conferidas nos arquivos. Não houve execução do jogo nesta alteração.

Abra [a galeria](splash_art_gallery.html) no navegador para ver e buscar as artes. Os prompts completos estão em [splash_art_prompts.json](splash_art_prompts.json).

## Ajuste de acabamento

O Palmito-juçara recebeu uma edição adicional pela mesma ferramenta para remover uma pequena marca gerada no canto inferior esquerdo, preservando o restante da composição. Prompt: “Remove the tiny signature/logo-like mark at the bottom-left corner, reconstructing matching dark forest foliage and soil beneath it. Preserve all other image content.”

O tamanho solicitado nos prompts foi 1024 × 1024; a ferramenta entregou 1254 × 1254, mantido sem redimensionamento.
