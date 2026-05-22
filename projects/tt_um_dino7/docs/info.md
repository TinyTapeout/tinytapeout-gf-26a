<!---
This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the first 1024 characters of the combined markdown files are used for metadata extraction.
--->

## How it works

Dino-7 is a minimalist endless runner inspired by the Chrome Dinosaur game, rendered on a single 7-segment display. The game uses a finite state machine with idle, run, jump, hit, and score-display behavior, plus pseudo-random obstacle generation and a retained high score.

### Game states

| State | Description |
|-------|-------------|
| `S_IDLE`  | Shows the stored high score on the 7-segment display |
| `S_RUN`   | Player is on the ground and obstacles advance |
| `S_JUMP`  | Player is in the air for a short fixed jump time |
| `S_HIT`   | Collision detected, all segments light up |
| `S_SCORE` | Final score is shown, alternating with high score |

### Display mapping

The 7-segment display is used as a tiny side-view game field with a horizontal obstacle flow:

| Output | Segment | Meaning |
|--------|---------|---------|
| `uo[0]` | `a` | Obstacle far (spawning) |
| `uo[1]` | `b` | Obstacle mid (approaching) |
| `uo[2]` | `c` | Player on ground |
| `uo[3]` | `d` | Obstacle has passed |
| `uo[4]` | `e` | Player in air (jumping) |
| `uo[5]` | `f` | Unused |
| `uo[6]` | `g` | Obstacle close (collision zone) |
| `uo[7]` | `dp` | Jump cooldown active / High score indicator |

### Obstacle movement

Obstacles move through four visible phases across the display:

1. `a` — a new obstacle appears far away.
2. `b` — the obstacle approaches the player.
3. `g` — the obstacle reaches the close collision zone.
4. `d` — the obstacle has passed.

A 32-bit LFSR is used to generate pseudo-random obstacle spawn timing from the seed bits on `ui[7:4]`.

### Jump and score logic

The player is shown on `c` while running and on `e` while jumping. After a jump, the decimal point turns on briefly to indicate jump cooldown, so the jump button is temporarily blocked.

If the player avoids an obstacle successfully, the score increments up to 9. The game speed increases gradually depending on the selected difficulty and score progression.

### Score and high score

In idle mode, the display shows the saved high score with the decimal point enabled. After a collision, the game briefly lights all segments, then shows the current score and alternates it with the stored high score.

## How to test

### Controls

| Pin | Function |
|-----|----------|
| `ui[0]` | Jump button (active high) |
| `ui[1]` | Game reset (active high) |
| `ui[3:2]` | Difficulty selector |
| `ui[7:4]` | LFSR seed bits |

### Step-by-step

1. Apply power and release `rst_n`.
2. The display starts in idle mode and shows the high score with the decimal point on.
3. Press `ui[0]` to start the game.
4. Watch the obstacle move through `a` → `b` → `g` → `d`.
5. Press `ui[0]` to jump before the obstacle reaches the close collision zone.
6. During cooldown, the decimal point turns on.
7. On collision, all segments light up, then the score screen appears.
8. Press `ui[1]` to reset the game and return to idle.

### External hardware

- One common-cathode 7-segment display connected to `uo_out[7:0]`
- One push button on `ui[0]` for jump
- One push button on `ui[1]` for game reset
- Optional switches on `ui[3:2]` and `ui[7:4]` for difficulty and seed selection