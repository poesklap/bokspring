# Bokspring

An Afrikaans learning game (a three-lane runner) for one returning learner on an iPhone.

**Read `BRIEF.md` before doing anything.** It is the full spec: game rules, learning engine, content, settings, architecture and milestones.

## Hard rules

- **Secrets:** all API keys and secrets go in `.env` only. Never commit, push, deploy, log or print them. Check staged files and build output for secrets before every commit and deploy. Never use `VITE_`-prefixed variables for secrets.
- **Subagents:** use subagents for visual design, audio, and writing the Afrikaans words and phrases. Use a second subagent to review the Afrikaans content before merging.
- **Reference material:** PDFs in `/reference` are for checking words, spelling and level only. Never copy their text or pictures into the app. `/reference` is never committed. The PDFs are not there yet: start without them, use best-guess translations, and list uncertain items in `content/UNVERIFIED.md`.
- **Architecture:** the learning engine in `src/engine/` has no UI code. A game skin works by implementing `SkinBase` only.
- **Delivery:** every milestone ends deployed to a public web link that works on iPhone Safari.
