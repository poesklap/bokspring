# Afrikaans content review (second reviewer)

## Summary

I reviewed all 185 items in Units 1 to 4, plus the 32 placement questions and 8 tips, against standard Afrikaans (AWS spelling). I did not have the reference PDFs. The draft is in good shape. Diacritics (môre, geëet, reën, reënboog, sê, bêre) are correct and every file is NFC precomposed with straight apostrophes. I made 28 changes (one table row each):

- **Answer safety (4):** the oranje/lemoen clash, the lig/helder overlap, the "kos = cost" placement trap, and an extra altEn on "sy".
- **Grammar and standard usage (6):** the non-standard "niemand … niks … nie", the idiom form "'n appeltjie vir die dors", and clock-time spelling (4 rows).
- **Wrong or imprecise grammar explanations (5):** 4 tips and 1 note.
- **Unnatural or factually odd examples and options (9).**
- **Glosses, altEn and tiers (3).**
- **Word replaced, with an id rename (1):** kleurvol → kleurryk.

**Greetings decision:** they are written as one word, following AWS and HAT: **goeiemôre, goeiemiddag, goeienaand, goeienag**. These are fixed greeting formulas, written as compounds like goeiedag. The draft already used these forms everywhere, so no change was needed. The note "Also written 'goeie môre'" is kept because the separate form is common and appears in BRIEF.md. All four rows were removed from UNVERIFIED.md.

All checks pass after the changes: JSON parses, ids are unique and match the pattern, required fields are present, `en`/`af` are unique ignoring case, no `altEn` equals another item's `en`, answers are 28 characters or fewer, examples are 60 or fewer, and placement options are distinct with a valid `correctIndex`.

## Changes

| id | field | before | after | why |
| --- | --- | --- | --- | --- |
| w_jy | exampleEn | You are very kind. | You are very friendly. | "vriendelik" = friendly; accurate gloss. |
| w_sy | altEn | (none) | ["his"] | "sy" also means "his" (as the note says), so the engine should never offer "his" as a wrong answer. |
| p_ek_verstaan_nie | note | Only one 'nie' here because the verb comes last. | One 'nie' only: it already ends the sentence. | The old rule was wrong ("Hy het nie gekom nie" has the verb last but two nie's). |
| w_agt | exampleAf | Die bus kom om agt uur. | Die bus kom om agtuur. | AWS writes clock times as one word; "agt uur" apart = eight hours. |
| w_duisend | exampleAf | Duisend mense was daar. | Daar was duisend mense. | More natural word order. |
| w_maart | exampleAf / exampleEn | Skool begin in Maart. / School starts in March. | Herfs begin in Maart. / Autumn starts in March. | SA schools start in January; the old example was factually wrong. |
| w_uur | note | …(drie uur = three o'clock). | …(drie-uur = three o'clock). | Matches the AWS clock-time spelling. |
| p_dit_is_drie_uur | af | Dit is drie uur. | Dit is drie-uur. | AWS clock-time compound, with a hyphen at the vowel clash. Id kept. |
| p_ons_het_om_agtuur_geeet | tier | 4 | 3 | Simple het + ge- past, the same as the other tier-3 past-tense phrases. |
| w_oranje | en | orange | orange (colour) | The English prompt "orange" had two right answers (oranje / lemoen "orange (fruit)"). |
| w_helder | en / altEn | bright / ["clear"] | clear / ["bright"] | "bright" is also a fair answer for "lig" (same category). "clear" is unambiguous. |
| w_helder | exampleAf / exampleEn | Die son is helder. / The sun is bright. | Die water is helder. / The water is clear. | Matches the new main gloss. |
| w_kleurvol → w_kleurryk | id / af / exampleAf | w_kleurvol / kleurvol / Die mark is kleurvol. | w_kleurryk / kleurryk / Die mark is kleurryk. | "kleurryk" is the standard, common word; "kleurvol" is marginal. Nothing in src/ or tests/ referenced the old id. |
| w_koeksister | exampleAf | Ouma bak koeksisters. | Ouma maak koeksisters. | Koeksisters are deep-fried; "maak" fits the English "makes". |
| w_lekkergoed | exampleAf / exampleEn | Te veel lekkergoed is sleg. / Too many sweets are bad. | Te veel lekkergoed is sleg vir jou. / Too many sweets are bad for you. | More natural in both languages. |
| w_sout | exampleAf | Gee my die sout, asseblief. | Gee vir my die sout, asseblief. | "Gee vir my" is the usual spoken form. |
| w_koeldrank | en / altEn / exampleEn | fizzy drink / [cool drink, soft drink, soda] / …a fizzy drink? | cooldrink / [cool drink, fizzy drink, soft drink, soda] / …a cooldrink? | The learner is South African, and "cooldrink" is the SA English word. |
| w_wortel | exampleAf | Die haas eet 'n wortel. | Die konyn eet 'n wortel. | "haas" = hare; the English says "rabbit" (konyn). |
| w_ontbyt | exampleAf | Ontbyt is om sewe uur. | Ontbyt is om sewe-uur. | AWS clock-time spelling. |
| p_die_koekie_is_vir_jou | altEn | (none) | ["The cookie is for you."] | koekie = biscuit or cookie. |
| pl_1_08 | options[0] | cost | coast | "kos" also means "costs" (Dit kos R20), so "cost" was a second right answer. |
| pl_3_04 | options[2] | I live at home with my sis | I stay home when it rains | Awkward wording; "bly" can also mean "live", which blurred it. |
| pl_4_05 | prompt | Niemand het niks gesien nie. | Niemand het iets gesien nie. | "niemand … niks" is non-standard (substandard) double negation; standard is "niemand … iets … nie". |
| pl_4_08 | prompt | Hy hou 'n appel vir die dors. | Hy bêre 'n appeltjie vir die dors. | The idiom is "'n appeltjie vir die dors bêre/hou" (diminutive). "bêre" is the most common verb. |
| tip_vowels | bodyEn | 'oe' like 'oo' in 'book' … 'Ui' is a rounded 'ay' sound. | 'oe' like 'oo' in 'food' … 'Ui' is close to 'ay' in 'say', but with rounded lips. | Afrikaans oe is the long "oo" of "food", not the short vowel of "book". |
| tip_double_negative | bodyEn | If the verb is already last, one 'nie' is enough. | If the first 'nie' already ends the sentence, the two merge into one. | The old rule was wrong (see p_ek_verstaan_nie). |
| tip_past_tense | bodyEn | put 'het' after the subject … be- or ver- skip the ge-. | 'het' takes the verb's place and the verb moves to the end with ge- … be-, ge-, ver-, er-, her- or ont- don't add ge-. | het is in verb-second position, not always after the subject (Gister het ek …). The prefix list was incomplete. |
| tip_diminutives | bodyEn | Add -ie or -tjie … | adds: Depending on the last sound, the ending can also be -kie, -pie or -etjie. | The tip's own example "rokkie" uses -kie, which the old text did not explain. |

No changes were needed to `units.json`.

## Checked and confirmed (removed from UNVERIFIED.md)

- **Greetings:** goeiemôre, goeiemiddag, goeienaand and goeienag are AWS one-word forms (see above).
- **w_jammer:** "adjective" is right (ek is jammer). Used alone, it works as an interjection, which is fine.
- **w_waar:** the "true" homograph is correct and useful. altEn handles it.
- **p_mooi_loop:** a very common, friendly SA goodbye; tier 2 is fine.
- **p_ek_het_jou_gemis:** correct; tier 3 fits with the other het + ge- items.
- **w_sewentig, w_tagtig, w_negentig:** tier 3 is a reasonable choice ("tagtig" is irregular).
- **w_uur:** the altEn "o'clock" is correct.
- **w_vanaand:** "tonight" / "this evening" does not clash with goeienaand ("good evening") or goeienag ("good night").
- **p_dit_is_half_drie:** "half drie" = 2:30 is the standard convention taught at school. Only the spelling stays listed.
- **p_ons_het_om_agtuur_geeet:** "agtuur" as one word is the AWS clock-time form. It is now covered by the clock-time row.
- **Months:** tier 2 and the capital letters are correct.
- **w_goue:** "goue" is the correct attributive form; tier 3 is fine.
- **w_rooierig:** the spelling is correct.
- **w_kleurvol:** replaced by kleurryk.
- **p_van_watter_kleur_hou_jy:** this word order is the standard written form.
- **w_pap, w_boerewors, w_mielie, w_aandete:** glosses are fine and altEn covers the variants.
- **w_koeldrank:** gloss changed to "cooldrink".
- **w_druiwe, w_ertjies:** plural items are correct Afrikaans. Whether the engine handles plural items is a code question, not a language one.
- **p_eet_smaaklik:** natural and common.
- **p_die_koekie_is_vir_jou:** koekie = biscuit is correct; cookie added as altEn.
- **pl_3_04, pl_4_08:** fixed (see table).
- **pl_4_07:** "die kat uit die boom kyk" = to wait and see how things turn out. The form and meaning are correct.
- **tip_vowels:** fixed. The approximations are reasonable for an English speaker.

## Still to confirm (fluent speaker or reference PDFs)

1. Clock-time spelling: drie-uur, sewe-uur, agtuur (AWS compound rule), and "half drie" vs "halfdrie".
2. **w_ekskuus vs w_jammer:** in everyday SA speech "Ekskuus!" also means "Sorry!". The game could mark a learner wrong for choosing "sorry" for ekskuus, or ekskuus for "sorry". The engine (`distractors.gd`) already keeps two items apart when one's altEn lists the other's `en`. Only the loader rule "altEn must not be another item's answer" blocks adding `"sorry"` to ekskuus's altEn. **Recommendation for the main agent:** relax that loader rule (treat a shared meaning as "never distract each other"), then add `"sorry"` to w_ekskuus altEn. Until then, keep ekskuus and jammer from being offered together.
3. **w_lig / w_bleek / w_helder:** slight overlap of shade words (light / pale / bright). Watch it in play.
4. **w_tee vs w_rooibos:** low-risk overlap.
5. Glosses: w_lekker "nice", w_koeksister "syrup doughnut", p_sy_het_n_rooi_rokkie "little red dress".
6. Tier pitch overall (1 basics … 4 matric). It looks sensible but has not been checked against the FAL curriculum documents.
