# Bokspring – Afrikaans Learning Game: Claude Code Brief

Nov 25, 2026 · Jonti

## Goal

Build a phone-first web game that teaches Afrikaans vocabulary and basic sentences through short, replayable arcade rounds. The game is Bokspring, a lane runner. The learning engine is kept separate from the game, so more game skins can be added later without losing progress.

- **Learner:** an adult English speaker who learned Afrikaans before and wants to pick it up again. Expect patchy recall: many words will come back quickly, so the placement test and fast early wins matter.
- **Session:** 2–5 minutes, played daily on a phone, one thumb.
- **Success:** the learner plays most days for 4 weeks and can recognise ~300 common words and produce ~100, measured by the app's own review stats.

## Design principles

Space Invaders was only ok because it splits attention: the player has to aim, dodge and read moving text at the same time, so either the game or the learning suffers. Bokspring follows five rules instead.

1. **One decision per beat.** Each moment asks one question with 2–4 choices, answered by a single lane change.
2. **The answer is the control.** Choosing the right word *is* the move (run into its lane), not a separate shooting step.
3. **Short rounds, instant retry.** Levels last 1–2 minutes; a "Weer!" (again) button restarts in under a second. Near misses drive "one more go".
4. **Speed ramps with mastery.** Pace rises as the streak grows and drops after a mistake, so the game stays at the edge of the learner's ability.
5. **Every mistake becomes a lesson.** After a wrong answer, show the correct pair for one second with audio, then feed it back into the review queue.

## Bokspring: the game

Bokspring is a three-lane endless runner where moving into the lane with the right answer is the only move. Other skins (Flappy-, Fruit Ninja- or Wordle-style) could be added later on the same engine, but they are out of scope for this build.

- **Player:** a young springbok running down a track, starting in the veld.
- **Control:** swipe left or right to change lane. No jumping, tapping or other controls.
- **Each beat:** a prompt (an Afrikaans or English phrase, or speech where the device has an Afrikaans voice) appears, with one answer at the head of each lane.
- **Outcome:** once the player commits to a lane, obstacles appear a moment later in every wrong lane. A wrong answer means a crash; the right one means a clear run.
- **Crash:** the player loses a life and the correct pair shows for a second with speech if available.
- **Level:** 10 phrases. The level is complete when all 10 have been answered correctly; a missed phrase comes back later in the same level.
- **Lives:** the player has 5 lives in total, and whatever is left carries over from level to level. The only way to get lives back is buying an extra life in the shop.
- **Game over:** losing the last life sends the player back to level 1 with 5 lives. Coins reset to zero and unused skips are lost; cosmetics and arenas are kept. Word mastery and the review schedule are never reset, so the learning carries on.
- **Coins:** earned for each correct answer, with bonus coins for streaks, and spent in the shop at the end of each level.
- **Pace:** the springbok speeds up as the streak grows and slows after a crash.

## Learning engine

All skins share one engine that decides *what* to ask; a skin only decides *how* it looks. A skin asks the engine for the next challenge, renders it, and reports the result.

```json
{
  "id": "c_0412",
  "type": "translate_af_en",
  "prompt": "hond",
  "promptAudio": "hond",
  "options": ["dog", "house", "hand"],
  "correctIndex": 0,
  "itemId": "w_hond"
}
```

- **Challenge types:** `translate_af_en`, `translate_en_af`, `listen_pick`, `word_order` (sentence building, phase 3).
- **Distractors:** pick from the same category and similar spelling (hond / hand / huis) so guesses are not free.
- **Spaced repetition:** a Leitner system with 5 boxes per item. Correct moves an item up a box; wrong sends it to box 1. Box intervals: same session, 1 day, 3 days, 7 days, 21 days.
- **Mix per round:** about 70% due reviews, 20% new items, 10% recent mistakes. Introduce at most 8 new words a day.
- **Fair timing:** time limits scale with prompt length and the learner's current box for that item.
- **Results:** `reportResult(itemId, correct, responseMs)` updates the box, XP and stats. The engine has no rendering code and full unit tests.

## Afrikaans content

Ship a starter deck of about 300 words and 60 short phrases as JSON in `/content`, so words can be added without touching code. Claude Code drafts the deck and checks it against the reference material below; no fluent reviewer is available. Content should run from everyday basics up to Grade 12 First Additional Language (matric) level.

| Unit | Example items |
| --- | --- |
| 1. Greetings and courtesy | hallo, goeie môre, dankie, asseblief, totsiens, hoe gaan dit? |
| 2. Numbers and time | een, twee, drie, vandag, môre, gister |
| 3. Colours | rooi, blou, groen, geel, swart, wit |
| 4. Food and drink | brood, kaas, vleis, melk, koffie, water |
| 5. Family and people | ma, pa, broer, suster, vriend, kind |
| 6. Animals | hond, kat, perd, koei, voël, vis |
| 7. Common verbs | eet, drink, gaan, kom, sien, praat |
| 8. South African everyday words | lekker, braai, bakkie, koppie |

Each item: `{ "id", "af", "en", "unit", "category", "partOfSpeech", "plural?", "exampleAf?", "exampleEn?", "audio?" }`.

Language points to build in as unlockable "tip cards" and later challenges:

- **Easy win:** verbs do not change by person (ek is, jy is, hy is). Tell the learner early; it is motivating.
- **Double negative:** Ek praat **nie** Afrikaans **nie**.
- **Past tense:** het + ge- (ek eet → ek het geëet).
- **Diminutives:** -ie / -tjie (hond → hondjie).
- **Sounds:** the throaty g, and the vowels ui, oe, ie, ê. Use these in listening challenges when the device has an Afrikaans voice.

**Reference material**

The PDFs go in the `/reference` folder, which is listed in `.gitignore`. See `reference/README.md` for the list and links. The content subagents use them to choose words, check spelling and pitch the levels; they must not copy text or pictures from them into the app.

## Progression and habit hooks

Progress belongs to the learner, not the game: XP, coins, streaks and word mastery are stored apart from the game code, so future skins can reuse them. Progress stays on one device, with export/import as a backup.

- **Daily goal:** 3 rounds or 50 XP, shown as a ring on the home screen. Hitting it extends the streak.
- **Streak with a safety net:** one free "streak freeze" a week, so one missed day does not kill motivation.
- **Combo multiplier:** x2 at 5 correct in a row, x3 at 10. Shown loudly with sound.
- **Coin shop:** coins from correct answers and streaks are spent in a shop shown at the end of each 10-phrase level. Items: an extra life; a skip button, where a skipped phrase goes into the Foute deck so it still gets learned; cosmetics for the springbok (hats, colours, glasses, clothes, flags); and arenas that change the track's setting, starting in the veld and unlocking the beach, snow, jungle, space and more.
- **Unlocks:** new units and levels unlock with XP, so there is always a next thing.
- **"Foute" deck:** a short round made only of recent mistakes, offered after any bad round.
- **Word garden:** a visual screen where each mastered word (box 5) grows a plant. Shows real progress, not just points.
- **Personal bests:** per level, with a "new record" moment.
- **Optional nudge:** one local reminder notification at a time the learner picks. No guilt messages.

## Start menu, settings and onboarding

The app opens on a start menu; first-time players get a short, skippable placement test that sets their difficulty.

- **Start menu:** Play, shop, word garden and stats, settings.
- **Onboarding (skippable):** a 2-minute adaptive test of about 12 questions. It starts with basic words and steps up to phrases and short sentences as the player gets them right, then places them at Beginner, Elementary (about Grade 7–9 First Additional Language), Intermediate (Grade 10–11) or Advanced (Grade 12). Skipping sets Elementary, since the learner has studied Afrikaans before.
- **What difficulty controls:** starting unit, game speed, number of choices (2–4 lanes), how similar the wrong answers are, and direction (Afrikaans → English first, English → Afrikaans later).
- **Manual difficulty:** the player can change the level in settings at any time; the engine keeps adapting within that level.
- **Settings:** difficulty, music and sound volume, speech on/off and speed, daily reminder time, reduce motion, colour-blind-friendly lanes, export/import progress, retake placement test, reset progress.

## Tech stack and architecture

A static, installable web app (PWA) with no backend: free to host, works offline, and the friend opens one link on their phone.

- **Stack:** Vite + TypeScript. Phaser 3 for the game; plain HTML/CSS for menus.
- **Storage:** progress in `localStorage` (or IndexedDB), with export/import to a JSON file as a backup.
- **Audio:** speech uses the device's built-in voice through the browser's speech synthesis, with an Afrikaans voice (`af-ZA`) when the phone has one. No paid speech service and no API keys. The friend uses an iPhone, and it is not confirmed that Safari on iPhone offers an Afrikaans voice, so test this on their phone in M1. Check at startup: if there is no Afrikaans voice, turn off listening challenges and speech settings, and tell the player once that they can add an Afrikaans voice in their phone settings if their phone offers one. Sound effects and music are files in `/audio`.
- **Hosting:** GitHub Pages or Netlify, deployed from the repo.
- **Layout:** portrait, one-thumb controls, large tap targets, works from 360px wide.

```text
src/
  engine/      # challenge generator, Leitner SRS, scoring (no UI, unit-tested)
  content/     # loader + validation for /content/*.json
  skins/
    SkinBase.ts   # interface: start(), onChallenge(c), onEnd()
    bokspring/    # lane runner skin (springbok, arenas, cosmetics)
  ui/          # start menu, onboarding, shop, stats, word garden, settings
  speech/      # device voice detection and playback
  storage/     # save/load progress
content/       # word and phrase decks (JSON)
```

Rule for Claude Code: a new skin must work by implementing `SkinBase` only, with no changes to `engine/`.

## How Claude Code should work

The main agent owns the architecture, the learning engine and integration, and hands three areas to subagents.

| Subagent | Owns | Delivers |
| --- | --- | --- |
| Visual design | Art style, UI, the springbok, arenas, shop cosmetics | Sprites and SVGs in `/assets`, a short style guide, UI components |
| Audio | Sound effects, music loops, speech playback | Audio files in `/audio`, a speech module that uses the device's Afrikaans voice and handles phones that have none |
| Afrikaans content | Words, phrases and example sentences for every unit and level | Validated JSON in `/content`, with uncertain items checked against the reference material and left out if still unsure |

A second content subagent reviews the first one's output for spelling, diacritics (ê, ë, ô) and natural phrasing before it is merged.

**Secrets**

- All API keys and secrets live in a `.env` file. `.env` is already in `.gitignore`; only `.env.example` with empty values is committed.
- Never push or publish secrets: not in commits, the deployed site, build output, logs, screenshots or messages. Check the staged files and the build output for keys before every commit and every deploy, and stop if anything looks like a secret.
- The current plan needs no API keys. If one is added later, it is used only by build-time scripts. The generated files are committed; the keys never reach the browser. Do not use `VITE_`-prefixed variables for secrets, because Vite bundles those into the public app.

**Web link**

- The app is deployed to a public URL (GitHub Pages or Netlify), and every milestone ends with a working link the friend can open and add to their home screen.

## Milestones and acceptance criteria

Ship Milestone 1 to the friend as soon as it works, then build the rest from their feedback.

| Milestone | Scope | Done when |
| --- | --- | --- |
| M1: Playable core | Engine + SRS, Units 1–4 (~150 words), Bokspring with the veld arena, levels and lives, start menu, settings, placement onboarding, XP and streak, deployed to a web link | Friend can install it on their phone, play a full round offline, and progress survives closing the app |
| M2: Variety | Coin shop (extra life, skip, cosmetics, new arenas), Units 5–8, listening challenges on devices with an Afrikaans voice, Foute deck, stats screen | Game over resets coins and level but keeps cosmetics, arenas and word mastery; skipped and missed phrases come back in later levels |
| M3: Habit and depth | Word garden, more arenas, sentence building (`word_order`), reminders | 4-week streak is possible without running out of new content |

Quality bar for every milestone:

- [ ] Engine unit tests pass (box moves, due dates, distractor choice).
- [ ] Runs at 60 fps on a mid-range phone; first load under 3 seconds.
- [ ] Restart after game over takes one tap and under 1 second.
- [ ] Every wrong answer shows the correct pair before the next challenge.
- [ ] Content JSON is validated at build time; a bad entry fails the build.
