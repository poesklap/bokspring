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

## Sentence review (80 phrase items, tiers 3–4)

Second, independent review of the 80 new sentences, combined with the user's request to make them **shorter**. All 80 phrase items were rewritten tighter. Each one keeps its id, tier, category and grammar point. Tier 3: af/en ≤ 70 chars. Tier 4: af/en ≤ 90 chars. All 4 `wrongEn` and 4 `wrongAf` options were rewritten to match, within the same limits. Every option was checked again to make sure it is clearly wrong and not an acceptable variant. Afrikaans word counts sometimes run 1–3 words over the targets (7–11 / 9–14) because of short words such as die, het and nie. The character limits are all met.

Copyright check: the content was compared with the two reference papers (`/reference`, extracted text). No sentence, distinctive phrase, name or storyline comes from them. The only overlaps are single common words (skoolhoof, fliek, stiptelik, aanspreekvorm). "aanspreekvorm" no longer appears in the content.

### Language fixes (beyond shortening)

| id | field | before | after | why |
| --- | --- | --- | --- | --- |
| p_geen_van_die_gaste_het_die | af / note / wrongAf | …het die brandrissiesous **probeer** nie… "Probeer takes no ge-." | Geen gas het die sous **geproe** nie… "Proe becomes geproe." | As a main verb with an object, "probeer" normally takes ge- ("Ek het alles geprobeer"). That made the wrongAf "geprobeer" a correct answer and the note wrong. No ge- is only right in "probeer + verb" (probeer verberg het), which stays in p_haar_beleefde_glimlag. |
| p_as_die_galery_die_skildery | af + all options | met leë hande **gesit** het | met leë hande **gestaan** het | The established idiom is "met leë hande staan". |
| p_die_kunsonderwyseres_het | af / en / note | dat ons groen **sal kry** … "Reported speech keeps 'sal'" | dat ons groen **kry** as ons … meng | The note went against the school rule for indirect speech (sal → sou). A general truth stays in the present, which fixes both problems. |
| p_die_gaste_is_by_die_deur_deur | af | Die gaste is by die deur **deur** die gasvrou… | Die gaste is deur die gasvrou self by die deur verwelkom. | Removed the clumsy "deur deur" clash. |
| p_die_besoekende_ministers_is_met | af | met die nodige **statigheid** ontvang | **plegtig** ontvang | "statigheid" (stateliness) does not mean "due ceremony". |
| p_die_toeris_het_gevra_of_iemand | af | die pad … kon **beduie** | hom die pad kon **wys** | More natural, current usage. Resolves the UNVERIFIED row. |
| p_die_tyd_is_n_rivier_wat_niemand | note | "Separable verbspoel" | "The separable verb verbyspoel" | Typo. |
| p_die_kurator_het_verduidelik_dat | en | faded **after** years of exposure | faded **because of** sunlight | "weens" = because of. |
| p_die_herfs_het_die_wingerde_met | af | met goud en koper **bestryk** | goud **geverf** | Shorter and avoids the uncertain figurative "bestryk". |
| p_die_gasvryheid_waarvoor_die | note | 'Bekend vir' becomes 'waarvoor'. | adds: ('bekend om' gives 'waarom') | Purist alternative mentioned; see UNVERIFIED. |
| p_die_kleurpalet_waarmee_die | note | "Abstract nouns … mark a formal register" | the note now explains the waarmee clause and the verb order | The old claim was vague. The second relative clause was replaced by "onbeskryflike" to fit 90 chars. |
| p_nadat_die_span_die_vergeelde | af | Nadat die span die … vernis versigtig verwyder het | Nadat die vergeelde vernis verwyder **is** | Shorter. Now a passive in the nadat clause (still tier 4). |
| tip_passive | bodyEn | 'is gebak' means 'was baked', not 'is baked'. | …means 'was baked' (or 'has been baked'), not 'is being baked'. | "Die brood is gebak" can also be read as a state ("is baked"). The contrast that matters is with word. |

tip_verb_final: checked, correct, no change.

### Shortening: content changes worth knowing (one line each; all other items are the same sentence, only tighter)

- p_aangesien_sy_die_nuwe_buurvrou: "nog nie ontmoet het nie" → "nie ken nie" (user's own example).
- p_ma_het_gese_dat_ons_die_bure: now only "Ma het gesê dat die bure ons hond teruggebring het." (drops the thank-you clause).
- p_hy_het_nooit_n_woord_van_dank: "'n woord van dank" → "dankie".
- p_toe_hy_die_nuwe_kollega_ontmoet: "die nuwe kollega" → "haar"; the salary clause is dropped.
- p_omdat_die_korrekte_aanspreekvorm: "die korrekte aanspreekvorm" → "etiket".
- p_die_voorsitter_het_die_gehoor: the youth committee → "'n komitee"; "behartig" → "verwelkom".
- p_die_onderwyser_het_aangekondig: "Die onderwyser" → "Juffrou"; date is now "die vyftiende" only.
- p_my_suster_wou_weet_hoe_laat_die: second reported question dropped.
- p_die_eerste_keer_wat_ek_die: relative clause dropped; still past tense with voltooi (no ge-).
- p_op_die_twee_en_twintigste_van: "van Mei" dropped; "huweliksherdenking" → "troudag".
- p_die_horlosie_teen_die, p_die_horlosie_wat_my_oupa_my_op, p_die_wedstryd…, p_indien_die_trein…: numbers and times kept, details trimmed.
- p_die_stiptelikheid_waarop_ons: "treindiens" → "treine"; the "past decade" phrase is dropped.
- p_hy_skuif_sy_take_altyd_op_die: now "Hy skuif alles op die lange baan, en gevolglik moes hy gisteraand tot middernag werk."
- p_nooit_tevore_is_soveel: second clause → "meer as vierduisend!".
- p_hoewel_die_skildery_net_uit_grys: "net uit grys en swart bestaan" → "net grys is".
- p_die_kunstenaar_wie_se_skilderye: the exhibition clause → "woon in Stellenbosch".
- p_vir_die_matriekafskeid_het_sy: "Vir die matriekafskeid" and "smaragdgroen" dropped; now "Sy het haar hare rooi gekleur en 'n groen rok by Ouma geleen."
- p_besoekers_mag_nie_aan_die: now "Jy mag nie aan die doek raak nie, aangesien vingers dit kan beskadig."
- p_die_rotsskilderye_is_eers_in_die: "in die negentiende eeu" → "eers onlangs"; "duisende jare" → "eeue".
- p_nerens_in_die_land_sal_jy_n: "blomtapyt" → "blomme"; uses "Namakwaland s'n"; the winter-rain clause is dropped.
- p_die_resensent_het_geen_blad_voor: second clause → "die uitstalling was smaakloos".
- p_wanneer_die_kole_wit_gloei_is: "is die vuur gereed en" dropped.
- p_die_heerlike_melktert_is: "tienjarige broer" → "klein boetie".
- p_die_kelner_het_gevra_of_ons_nog: "voordat die kombuis … sluit" → "voor tienuur".
- p_geen_van_die_gaste_het_die: "Geen van die gaste" → "Geen gas" (see fix above).
- p_jy_moes_die_koek_nie_so_lank_in: "in die oond gelos" → "gebak".
- p_die_gasvryheid_waarvoor_die: the "toe die boervrou…" clause is dropped.
- p_die_inspekteur_het_die_eienaar: "die restaurant … indien die kombuis nie … skoongemaak word nie" → "die kombuis gesluit sou word indien dit vuil bly".
- p_die_geur_van_kaneel_en_naeltjies: "naeltjies" dropped; now "…elke gas kombuis toe gelok".
- p_aangesien_die_vraag_na_plaaslike: now "…om plaaslike boere aan te stel".

### Removed from UNVERIFIED.md (confident)

- p_die_toeris…: "beduie" replaced by "wys".
- p_omdat_oupa…: the "saans" word-order question is gone because "saans" was dropped.
- p_die_nuwe_kunsonderwyser…: "net 'n blou Maandag" is a standard, well-known idiom.
- p_hy_skuif…: "op die lange baan skuif" is the dictionary (HAT) form.
- p_na_die_droogte…: "so skaars soos hoendertande" is a long-established Afrikaans idiom (HAT), not a recent calque.
- p_toe_dit_aan_die_lig_kom…: "vervals" (to adulterate food or drink) is a standard dictionary sense.
- p_die_herfs…: "bestryk" no longer used.
- p_die_rotsskilderye…: "aanbring" is the normal formal verb for putting paint or art on a surface.
- p_die_ou_ketel…: "het staan en fluit" is standard, and no wrong option uses "gestaan en gefluit".

Added to UNVERIFIED.md: p_die_gasvryheid (bekend vir/om) and p_die_kunsonderwyseres (present tense for a general truth in reported speech).
