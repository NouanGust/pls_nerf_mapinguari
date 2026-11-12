# Relatório Técnico — Unidade 3D Pequi (*Caryocar brasiliense*)

> **Unidade:** Pequi (`pequi`)  
> **Papel:** Suporte / Vegetal Estacionário (`is_stationary = true`)  
> **Origem / Bioma:** Cerrado | Seiva & Vigília | Flora  
> **Motor de Destino:** Godot 4.6.3 Engine  

---

## 1. Resumo Executivo das Entregas

A modelagem da unidade **Pequi** foi executada com fidelidade à botânica real do Cerrado (tronco tortuoso, inclinado, casca suberosa e ramos ondulantes) integrando a drupa aberta com polpa amarelo-ouro e o endocarpo eriçado de espinhos afiados.

| Componente | Especificação | Status |
|---|---|---|
| **Formato e Fonte** | Blender 5.2 / GLB / Godot TSCN | Concluído (`pequi.blend`, `pequi.glb`, `pequi.tscn`) |
| **Contagem de Triângulos** | 2.200 triângulos / 1.178 vértices | Excelente (teto máximo permitido: 15.000) |
| **Material & Texturas** | 1 Material PBR Atlas 1024x1024 (Base Color, Normal, Emissive) | Concluído |
| **Esqueleto (Armature)** | 14 ossos com hierarquia orgânica de árvore | Concluído (`Pequi_Armature`) |
| **Skinning** | 100% dos vértices ponderados ($\le 4$ influências) | Validado (0 vértices soltos) |
| **Animações NLA** | 6 animações de gameplay (`Idle`, `Attack`, `Ability`, `Channel`, `Stunned`, `Death`) | 100% Validadas no Godot |
| **Integração no Motor** | Recurso `resources/units/pequi.tres` atualizado | Aprovado em teste automatizado |

---

## 2. Apresentação Texturizada PBR

![Prancha de Apresentação Texturizada](file:///C:/Users/Professor/.gemini/antigravity/brain/8d64f2bc-a675-4a71-b613-580d14bea8a8/pequi_textured_presentation.png)

---

## 3. Montagem das 6 Animações de Gameplay

![Montagem de Animações](file:///C:/Users/Professor/.gemini/antigravity/brain/8d64f2bc-a675-4a71-b613-580d14bea8a8/pequi_animations_montage.png)

1. **Idle (2.5s):** Respiração e oscilação rítmica da árvore e dos galhos no vento do Cerrado; semente pulsa suavemente no cálice central.
2. **Attack (1.66s):** O tronco tensiona como uma catapulta orgânica para trás e estala para a frente, arremessando a semente com espinhos.
3. **Ability (2.08s):** Tronco ergue-se, galhos abrem-se em reverência mística ao céu e a semente sobe e emite uma explosão de seiva dourada curativa.
4. **Channel (1.25s loop):** Vibração rápida contínua de concentração da aura de defesa.
5. **Stunned (1.66s):** Tronco recua fadigado e os galhos murcham em direção ao solo.
6. **Death (1.87s):** A madeira perde sustentação, a árvore desaba para a frente e os galhos se espalham pelo solo do tabuleiro.

---

## 4. Validação Técnica no Godot
O teste automatizado [tests/test_pequi_model.gd](file:///c:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/tests/test_pequi_model.gd) executou via console Godot headless confirmando:
- Carregamento e instanciação da cena vinculada em `resources/units/pequi.tres`.
- Presença e execução com sucesso de todas as 6 animações no `AnimationPlayer`.

