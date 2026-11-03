# Publicar Folchess no itch.io

Versão preparada: **0.1.0**, Godot **4.6.3**. Destinos: navegador em computador e Windows x64. O jogo usa mouse e teclado.

## Gerar os pacotes

No PowerShell, na raiz do projeto:

```powershell
./tools/build_release.ps1 -GodotPath "C:/caminho/Godot_v4.6.3-stable_win64.exe"
```

Instale os templates de exportação **4.6.3.stable** pelo Godot se ainda não estiverem disponíveis. O script importa os recursos, exporta em modo release, testa cada pacote isolado da pasta fonte e cria uma pasta nova em `builds/release-AAAAmmdd-HHMMSS/` com:

- `folchess-web.zip`: `index.html` e todos os arquivos web na raiz do ZIP.
- `folchess-windows.zip`: executável, pacote de recursos e instruções.
- `SHA256SUMS.txt`: hashes dos arquivos.
- Logs de importação/exportação, fora dos ZIPs.

Os presets ficam em `export_presets.cfg`. Eles exportam os recursos do projeto, incluindo cenas e modelos carregados por código. Documentação, testes, ferramentas e builds anteriores são excluídos. Os retratos são importados com limite de 512 pixels; os PNGs originais são preservados.

## Configuração da página

1. Crie ou edite o projeto em [itch.io](https://itch.io/game/new).
2. Título: **Folchess**. Tipo: **HTML**. Estado de desenvolvimento: **In development**.
3. Envie `folchess-web.zip` e marque **This file will be played in the browser**.
4. Configure a área do jogo em **1280 × 720**, com opção de tela cheia. Use **Click to launch**.
5. Deixe a opção de SharedArrayBuffer desativada: a exportação web usa uma única thread.
6. Envie `folchess-windows.zip` como download e marque apenas **Windows** nesse arquivo.
7. Salve inicialmente como **Draft**, confira a prévia e então altere a visibilidade para **Public** quando quiser publicar.

O ZIP web deve ser enviado inteiro, sem renomear os arquivos internos. Ele precisa de um servidor HTTP; abrir `index.html` diretamente do disco não reproduz o comportamento do itch.io.

## Texto curto sugerido

**Folchess** é um auto battler inspirado na fauna, na flora e nas lendas do Brasil. Monte sua equipe, combine sinergias e enfrente seis regiões. Animais avançam pelo campo; plantas defendem sua posição com ataques à distância e auras.

**Controles:** arraste para posicionar, Espaço para iniciar o combate, R para atualizar a loja, L para travar, Q para comprar XP e S para vender a unidade sob o cursor. Botão direito inspeciona; botão do meio gira a câmera e a roda ajusta o zoom.

## Verificações antes de tornar público

Abra a build web pela prévia do itch.io e a versão Windows após extrair o ZIP inteiro. Confira seleção de região, compra e posicionamento, sinergias, um combate e o relatório final. No navegador, confirme a tela cheia e a legibilidade em 1280 × 720. A preparação local não publica nem altera uma página no itch.io.

Referências: [envio de jogos HTML5 no itch.io](https://itch.io/docs/creators/html5) e [exportação web no Godot 4.6](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_web.html).
