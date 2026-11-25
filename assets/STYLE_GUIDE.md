# Bokspring style guide

Flat, friendly vector art of the South African veld in warm late-afternoon light. Bold rounded shapes, a dark brown ink outline (`#3A2416`) on characters and props, few colours, strong contrast for small phone screens. All art is original. Colours used in code live in `src/ui/style.gd`.

## Palette

| Role | Hex | Use |
| --- | --- | --- |
| BG | `#FBEFD9` | Menu background (warm cream) |
| PANEL / border | `#FFF8EC` / `#E8CFA4` | Cards, dialogs |
| PRIMARY | `#E0662B` | Main buttons (sunset orange) |
| PRIMARY_DARK | `#A8441A` | Button lip, pressed state |
| ACCENT | `#3D8FD0` | Secondary buttons, focus ring |
| TEXT / TEXT_MUTED | `#2B1D14` / `#7A6450` | Body text / hints |
| GOOD | `#1B6FB0` | Correct answer (blue) |
| BAD | `#D9480F` | Wrong answer, crash (vermilion) |
| GOLD | `#F5C542` | Coins, XP, stars |
| INK | `#3A2416` | Art outlines, HUD text outline |
| Springbok | `#C98A4B` tan, `#5A3220` flank stripe, `#FFF8EE` white | Player |
| Track | `#B5562F` (dark `#8E3F22`) | Red-brown dirt track |
| Grass | `#D9A441` / `#E3B04B` | Golden veld |
| Sky | `#3D86D4` to `#F8C47E` | Gradient towards the horizon |
| Koppies | `#B98A78` far, `#8A5A44` near | Horizon hills. Use `#8A5A44` as the 3D fog/horizon colour |
| Acacia | `#4F6B2A` / `#6E8B3D` | Tree canopy |

## Typography

Godot's default font only, no font files. Sizes at 540 px design width: 20 small or muted, **26 base**, 32 buttons and HUD, **44 titles**, 64 for the big prompt. Use the type variations in `Style.make_theme()`: `TitleLabel`, `HugeLabel`, `MutedLabel`, `HudLabel` (white with an 8 px ink outline over the 3D view), `SecondaryButton` and `GhostButton`. Answer text on signs is `TEXT` on the light board, 26 to 32 px, shrunk to fit the 220×80 safe area.

## Shapes

- Corner radius 18 on buttons, 24 on panels, 14 on inputs.
- Buttons have a 6 px darker "lip" underneath and sink when pressed.
- Props are chunky silhouettes with 6 to 10 px ink outlines. Scenery has thinner outlines (6 to 7 px) and softer, greener or browner colours.

## How game objects should read

- **Lanes:** subtle darker ruts (`lane_rut.svg`) on the track, never bright lines. The lane colour (`LANE_COLORS`) appears only as the answer sign's border or post tint, plus a brief glow on the lane you choose.
- **Answer signs:** light cream board (`#F6E2B8`) with a dark wooden frame. The text goes in the middle 220×80 px of the 256×128 sign. Keep signs facing the camera (billboard) and large enough to read at a glance.
- **Obstacles** (rock, thorn barrier, log) are the only objects with a near-black outline (`#1E140D`, 9 to 10 px) and a heavy shadow. They are grey or dark, cut across the lane, and must never be confused with scenery. Scenery stays off the track.
- **Feedback:** correct means a GOOD-blue flash, a ✓ icon and a coin. Wrong means a BAD-vermilion flash, a ✗ icon and the crash pose. Always show a shape or icon as well as the colour.

## Colour-blind guidance

- Never rely on red versus green. GOOD is blue and BAD is vermilion, and each always comes with ✓ or ✗.
- With the colour-blind setting on, lanes use `LANE_COLORS_CB` (Okabe-Ito orange, deep blue, yellow, sky blue). Neighbouring lanes alternate light and dark and blue and orange. Add `LANE_PATTERN_NAMES` (dots, stripes, plain, checks) on the sign border or lane glow.
- Hearts change shape as well as colour: full red heart versus empty outline.

## Tap targets

- Every tappable control is at least **64 px** tall at 540 px design width. Themed buttons are about 73 px and switches 64 px.
- `HSlider`'s grabber is 40 px, so give sliders `custom_minimum_size.y = 64`.
- Keep 16 px gaps between controls. Primary actions sit in the bottom half so they are easy to reach with one thumb.

## Motion

- Run cycle: 6 frames at about **12 fps** at normal speed. Scale up to about 16 fps as the game speeds up.
- Use quick tweens of 150 to 250 ms with ease-out. Signs pop in with a small overshoot. Coins spin by flipping their x scale.
- **Reduce motion:** no camera shake, no screen flashes (use a static coloured border instead), no sign overshoot, slower fades, and freeze the coin spin. The run cycle may keep playing, but drop the vertical camera bob.
