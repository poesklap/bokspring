# Bokspring audio

All audio here is original. It was composed and synthesised for Bokspring, with no samples, loops or melodies taken from anywhere else. The only third-party input is the instrument soundfont used to play back our own MIDI (VintageDreamsWaves v2, which ships with FluidSynth).

## Sound effects (`sfx/`): 44.1 kHz, mono, 16-bit WAV

| File | Length | Peak | Use |
|---|---|---|---|
| `correct.wav` | 0.39 s | -3 dB | Right answer: a bright two-note chime (C6 to G6) |
| `wrong.wav` | 0.45 s | -4 dB | Wrong answer: a soft low "bonk" |
| `crash.wav` | 0.53 s | -3 dB | Crashing into an obstacle: a soft thud plus the bonk |
| `lane.wav` | 0.12 s | -10 dB | Lane change: a tiny filtered-noise whoosh, quiet on purpose |
| `combo2.wav` | 0.83 s | -1 dB | x2 combo: a loud C-major brass-style fanfare stinger |
| `combo3.wav` | 0.94 s | -0.8 dB | x3 combo: a bigger D-major fanfare with an octave-doubled run, a fuller chord, sparkles and a cymbal |
| `coin.wav` | 0.23 s | -4 dB | Coin pickup: a short two-blip sparkle (B6 to E7) |
| `level_complete.wav` | 1.60 s | -3 dB | Level complete: a happy rising jingle ending on a major chord |
| `game_over.wav` | 1.60 s | -4 dB | Game over: a gentle falling phrase onto a warm chord, not punishing |
| `tap.wav` | 0.05 s | -6 dB | UI button click |
| `new_record.wav` | 1.00 s | -2 dB | New high score: a triumphant flourish with a trill |
| `countdown.wav` | 0.15 s | -6 dB | One 3-2-1 beep (play it three times) |

Every effect is trimmed, has a 2 ms fade-in and a short fade-out so it doesn't click, and is peak-normalised (levels are in the table). The two combo stingers are lightly saturated so they sound loud.

## Music (`music/`): Ogg Vorbis, 44.1 kHz stereo, about 128–140 kbps

| File | Loop length | Tempo / bars | Size | Use |
|---|---|---|---|---|
| `run_loop.ogg` | **46.08 s** (exactly 2,032,128 samples) | 125 BPM, 24 bars of 4/4 | 790 KB | In-run music. Kwela-style in G major: a pennywhistle-like lead, marimba, walking bass, off-beat "chop" chords, light drums with maracas, tambourine and conga fills. Form: A (G–C–G–D ×2), B (C–G–D–G–C–G–D–D), then A' with the marimba doubling the tune. The last bar is on D (the V chord), so it resolves into bar 1. |
| `menu_loop.ogg` | **32.00 s** (exactly 1,411,200 samples) | 90 BPM, 12 bars of 4/4 | 477 KB | Menus. Calm and warm, in F major: a vibraphone melody over a harp arpeggio, a soft pad and bass. F–Dm–Bb–C / F–Am–Bb–C / Dm–Bb–Gm–C, where the closing C chord leads back to F. |

Each file is exactly one loop long, starting on a bar line, so it should be played with looping on from offset 0. In Godot, tick **Loop** in the `.ogg` import settings (or set `AudioStreamOggVorbis.loop = true` with `loop_offset = 0`).

How the seamless loop is made: the MIDI holds three passes of the piece back to back. Only the middle pass is kept, so reverb and note tails from the end of the piece are already sounding under its first bar. The last 0.4 s is then crossfaded into the end of the first pass. That pass's natural next sample is the first sample of the kept pass, so the wrap point flows on without a jump. After encoding, the jump at the wrap point is smaller than the jump between normal neighbouring samples.

Levels (ffmpeg volumedetect): run_loop has a mean of -16.1 dB and a peak of -1.5 dB. menu_loop has a mean of -17.0 dB and a peak of -1.6 dB. Nothing clips.

## How it was made

- **Sound effects:** `source/sfx.py` uses only the Python standard library. It builds additive bell partials, band-limited saw "brass", pitch-swept sines and one-pole-filtered noise, then shapes them with envelopes and writes them with the `wave` module.
- **Music:** `source/music.py` holds the original compositions, written as MIDI by `source/midi.py`, a small writer built on `struct`. `source/render.py` renders them with FluidSynth (chorus off, reverb on) and cuts out the seamless loop. ffmpeg then encodes the result with its built-in Vorbis encoder at `-q:a 4`.
- **Rebuild:** run these from a scratch directory:
  ```
  python3 sfx.py <out_dir>
  python3 music.py
  python3 render.py run.mid run_full.wav 125 24 run_loop.wav
  python3 render.py menu.mid menu_full.wav 90 12 menu_loop.wav
  ffmpeg -i run_loop.wav -c:a vorbis -strict -2 -q:a 4 run_loop.ogg   # and the same for menu_loop
  ```
- `source/` has a `.gdignore` file, so Godot doesn't import the scripts.

## Speech

Spoken Afrikaans is not stored as files. `src/speech/speech.gd` uses the device's own Afrikaans voice if it has one, and stays silent if it doesn't. It never falls back to an English voice.
