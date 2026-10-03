# Research Report: STEPBible & MyBible — Downloadable-Module Bible Reader Apps

**Scope note:** This report covers two *products* that each ship several surfaces (web, desktop, mobile). Where a claim applies to only one surface I say so explicitly, because the two apps differ sharply between surfaces.

**Legend:** ✅ VERIFIED (primary/first-party source cited) · 📄 VERIFIED (third-party source cited) · 🔶 INFERENCE (reasoned from evidence, not stated) · ⚠️ CONFLICT (sources disagree)

---

## 0. CRITICAL PREMISE CORRECTIONS (read this first)

Three premises in the brief do not survive contact with the sources. They materially change the recommendations.

### 0.1 STEPBible is not a Chinese Bible app with a mobile module catalog

| Claim in brief | Reality | Source |
|---|---|---|
| "Chinese Bible app" | STEPBible is a scholarly project of **Tyndale House, Cambridge** (now an independent UK Charitable Incorporated Organisation, #1193950), with an English name and 50 UI languages. The Chinese Union Version is merely one of the two texts bundled in the mobile app. | [stepbible.org](https://www.stepbible.org/), [stepbibleguide.blogspot.com](https://stepbibleguide.blogspot.com/p/who-makes-stepbible.html), [STEPBible-Data](https://stepbible.github.io/STEPBible-Data/) |
| "known for a large downloadable module catalog" on Android/iOS | ✅ The catalog is real and large (**706 distinct version entries** counted on `versions.jsp`), but it belongs to the **web app and the install4j desktop app (Win/Mac/Linux)**. The **mobile app has no module download at all.** | Counted from [versions.jsp](https://www.stepbible.org/versions.jsp); [stepmobile README](https://github.com/STEPBible/stepmobile) |
| "Android/iOS" app | ⚠️ The Android app was **removed from Google Play on 10 Nov 2024** (33K lifetime installs, 4.31★/110 ratings, last update 5 Mar 2024). The iOS app exists (v3.0.14). Both are React Native/Expo apps that ship **one pre-built `bible.db` inside the bundle** — 70.9 MB APK / 188.5 MB iOS. | 📄 [AppBrain](https://www.appbrain.com/app/step-bible-scripture-tools-fo/com.tyndale.stepbible); [stepmobile README](https://github.com/STEPBible/stepmobile) ("Copy a pre-built database into the repo"); [step-bible.appstor.io](https://step-bible.appstor.io/) |

**Consequence:** STEPBible is a superb reference for *desktop-style* SWORD-module management, and a **cautionary tale** for mobile. Do not model the mobile app on it.

### 0.2 "My Bible" is at least six different products

| Product | Domain / ID | Module system? | Notes |
|---|---|---|---|
| **MyBible by Denys Dolganenko** ← *this is the one you want* | **mybible.zone**, Play `ua.mybible` | ✅ SQLite3 module downloads | Android native; iOS separate app. 4.7★ / 40.5K reviews / 1M+ downloads |
| **MyBible (mybible.com)** — "MyBible Social App" | mybible.com, App Store `1166291877` is Dolganenko's, but **mybible.com itself is a different social-reading product** | ❌ | Account + Facebook login, public activity feed, reading plans, "Facebook Covers". Hosted on CloudFront. |
| MyBible by Serhii Maksymenko | App Store `1166291877` (Dolganenko's iOS build, listed under Maksymenko) | ✅ (smaller) | iOS only; the under-served sibling |
| MyBible (Canadian Bible Society) | App Store `6670254162` | ❌ | Has **Verse of the Day**, audio, 3.2★/185 — a different app entirely |
| MyBible (mybible.ro, Romanian/Adventist) | App Store `948744181` | Audio downloads | Has **account + server sync**, daily devotional |
| MyStudyBible | App Store `6743988874` (Korean) | ✅ but **user-supplied only** | App "does not include content"; you drop SQLite files into 7 folders. Interesting opposite model. |
| MyBible (Laridian) | Palm/Windows, 1999–2003 | ✅ | Historic namesake; **paid** ($10 program + texts). The module-download pattern's ancestor. |
| MyBible (Free Bible Software Group, mybible.de) | mybible.de | Zefania XML | French project, Mathieu Delarue. Unrelated. |

**"Free Bible Software"** in the brief appears to be a conflation of **Free Bible Software Group** (the French Zefania project) with **Free Bible Software** as a generic descriptor. I found no company called "Free Bible Software" operating mybible.com. 🔶

### 0.3 "Distinctive vector-art Bible editions" / "My Study Bible" — NOT VERIFIED

I could not find any evidence of vector-art Bible editions in either target app.
- The only "vector" hit for MyBible is a **logo** asset filename (`logo-flame-vector-DPe5bIhP.png`) on a third-party landing page (mybibleapp.com).
- **MyStudyBible** is a real app (Korean, iOS) but it is a *separate* app with **no bundled content** — the store listing explicitly says the app "does not include Bible text, cross-references, commentary or other content" and only loads SQLite files the user supplies.
- Closest real analogues: MyBible supports **maps as dictionary modules containing scanned images + JavaScript** ([Maps tip](https://mybible.zone/android/tips/main/maps/)) ✅, and STEPBible ships a "Picture" resource index and image-capable commentary modules. 🔶

**Treat "vector-art editions" as unverified and drop it from your requirements until someone produces a source.**

---

# APP 1 — STEPBible

## A) Reading experience

### A.1 Surfaces

| Surface | Layout | Offline? |
|---|---|---|
| Web (stepbible.org) | Multi-panel browser app; panels open/close/resize side-by-side | No (cached URL only) |
| Desktop (install4j, v26_1_2) | Same UI served from `localhost` | ✅ Yes — "ESV, NIV and ancient language Bibles are included" |
| Android / iOS | Single scrolling pane, static DB | ✅ Yes (bundled DB) |

✅ [downloads.jsp](https://www.stepbible.org/downloads.jsp) — "Run STEPBible from your computer when disconnected from the internet. ESV, NIV and ancient language Bibles are included. It works in 50 languages and additional Bibles can be downloaded in 280 languages."

### A.2 Layout & scrolling

- Continuous scrolling chapter-by-chapter with explicit prev/next chapter buttons. ✅ [stepbible.org](https://www.stepbible.org/)
- **Desktop/web has no paging either** — but the *mobile app* has no swipe-to-next-chapter and reviewers notice: *"It would be nice if you can turn the page as you read. Instead you have to go out of STEPBible to select the following chapter."* — Irod1971, App Store ✅
- Verse numbering rendered inline as superscript-ish numerals; red-letter option separate. ✅ (screenshot of Gen 1 on homepage)

### A.3 Verse highlighting & current-verse tracking

✅ STEPBible web/desktop **does not highlight the current verse in the text pane**. Instead it uses a **hover model**: hovering a word shows a Quick Lexicon; hovering a verse number shows "verse vocabulary" (the Greek/Hebrew words in that verse with counts). Both are toggleable. This is a hover-first design that has no mobile analogue and that STEP's mobile app simply dropped.

### A.4 Typography controls

✅ Very limited on web/desktop: **font size** only, plus toggles for headings, verse numbers, verses-on-separate-lines, Jesus-words-in-red, Quick Lexicon, verse vocabulary, vocabulary language, grammar, colour-coded grammar. ([Display Options](https://stepbibleguide.blogspot.com/p/display.html))

❌ **No font family choice, no line-height, no custom colours, no light/dark/sepia theme system on the web product.** (The *Confluence* "Personalising" page is a stub: literally contains the text "TODO". ✅)

✅ **Mobile app added Dark Mode in v3.0.13** (iOS, 3 Apr 2022) — 📄 [soft112 changelog](https://step-bible-ios.soft112.com/): *"• Dark Mode • La Santa Biblia Reina-Valera (1909) • Spanish-Greek lexicons • Chinese-Greek and Chinese-Hebrew lexicons"*. Reviewer: *"Really appreciate the newly added dark mode. Thanks for making STEPBible and keeping it ad-free!"* — ItsDerek ✅

⚠️ The mobile app has **no light/dark toggle and no sepia** — only system-follow dark mode. 🔶

### A.5 Parallel translations — STEP's standout feature

✅ Five display modes, documented in detail ([Bible Displays](https://stepweb.atlassian.net/wiki/spaces/SUG/pages/9797667/Bible+Displays), [Display Options](https://stepbibleguide.blogspot.com/p/display.html)):

1. **Interleaved** — versions grouped verse-by-verse
2. **Interleaved with comparison** — word-level difference highlighting (same-language tagged texts only)
3. **Column view** — each version its own column, one row per verse
4. **Column view with comparison** — same + word-level diff
5. **Interlinear** — aligned word/phrase columns

Comparison mechanics ✅: text is lowercased, Greek/Hebrew accents and pointing stripped, partial-word differences flagged ("restores"/"refreshes" in Ps 23:3), **first-listed version is the "Master"** and governs chapter/verse numbering; drag version chips to change the master.

**Versification handling is unusually rigorous** ✅ — an entire documentation section explains that Ps 56:13 is Ps 56:13 (English) / 56:14 (Hebrew) / 55:13 (Latin) / 55:14 (Greek), with the LXX merging Ps 9–10 and splitting Ps 147. This is a genuinely excellent reference implementation for us.

### A.6 Interlinear / original-language display

✅ Best-in-class among free tools:
- **Interlinear** and **"reverse interlinear"**: *"In STEP you can pick any interlinear version to determine the order, simply by clicking on the version name under the verse number… display the interlinear in the order determined by any version — Hebrew, English, Russian, Chinese etc."* ✅
- Toggle pointing (niqqud) and accents on/off ✅
- Vocabulary in English / Greek-Hebrew / transliterated ✅
- **Colour-coded grammar** ✅
- Morphology codes expanded in open datasets (TEHMC/TEGMC) ✅

❌ **None of this is in the mobile app** except tap-word → original word + list of meanings.

---

## B) Navigation

### B.1 Books / chapters / jump-to-reference

✅ Web/desktop: find bar with a version dropdown + free-text reference box; the whole app state is encoded in the URL (`?q=version=ESV&reference=Gen.1`). Shareable, bookmarkable, and **configurable as a Chrome custom search engine** with `reference=%s` so typing `step Jn 3` opens a preconfigured multi-column layout. This is a genuinely great idea. ([Personal setup](https://stepbibleguide.blogspot.com/p/personal.html))

✅ STEP also builds **reference/visual reports** rather than expecting module authors to: Harmony of the Gospels, Miracles, NT Letter Structure, OT parallels, OT used in NT, Names of God, Prophets, Places, People (genealogy), **Chronology**, **Reading Plans**. ✅

❌ **No reading-plan tracking UI.** 📄 A third-party reviewer: *"No reading-plan, devotional, or community layer — this is a study tool, not a daily-reader tool."* ([learnofchrist](https://learnofchrist.com/resources/stepbible))

### B.2 Search — STEP's actual strength

✅ Extremely powerful query language: word/phrase, original-language word search, "words meaning" (semantic-domain) search, Strong-number search, subject search via **Nave's Topical Bible**, morphology filters, multi-module search, **word cloud** of a passage, "related verses" (same vocabulary) and "related subjects" per verse.
⚠️ Discoverability cost ✅ (documented by third parties): *"the search syntax is powerful but not intuitive, and the help docs are scattered… killer functions are buried behind icons that don't explain themselves until you click them. New users routinely use it for a year before realizing what it can actually do."* ([learnofchrist](https://learnofchrist.com/resources/stepbible))

### B.3 Bookmarks, notes, highlights, history

✅ Sidebar with **Bookmarks** and **Recent texts** tabs. Each row has three icons: *Go to*, *Pin*, *Dismiss*. ✅

🔴 **Bookmarks are stored in browser cookies.** ✅ Verbatim: *"STEPBible stores your bookmarks in cookies in your browser. You will have access to them for as long as the cookies remain in your browser. For more-permanent storage, consider the solution described below."* The "more permanent" solution is *"copy and save the URL, or create a Personalized Browser Bookmark."* **There is no notes feature, no highlighting, and no export.** ([Personal setup](https://stepbibleguide.blogspot.com/p/display.html))

Reviewer: *"I like STEPBible a lot… but I wish STEPBible developer would make it to where you could highlight certain verses of scripture."* — Drew10100 ✅

---

## C) Study tools

| Tool | Web/Desktop | Mobile |
|---|---|---|
| Cross-references | ✅ (from "N" modules, e.g. RST-x equivalents) | ❌ |
| Commentaries | ✅ **~30+ on versions.jsp** (Barnes, Calvin, Clarke, JFB, Keil & Delitzsch, MHC, RWP/Robertson, Scofield, Spurgeon, TSK, Tyndale Open Study Notes, Wesley, Kittel, Frederick, GerKingComments…) | ❌ |
| Dictionaries / lexicons | ✅ (BDB, LSJ/Thayer-derived, abridged sets) + "related words" | ⚠️ Word meanings only |
| Strong's numbers | ✅ | ✅ (tap word) |
| Morphology / grammar | ✅ + colour coding | ❌ |
| Textual apparatus | ✅ **"Apparatus… showing what the original manuscripts said (much more in preparation)"** — manuscripts (Aleppo Codex, Leningrad/WLC, Samaritan Pentateuch, Peshitta, Vulgate, Sahidic Coptic, multiple Greek NTs) | ❌ |
| Footnotes | ✅ (NETfull has "the most comprehensive notes of all STEPBible's Bible versions") | ❌ |
| Maps / images | 🔶 partial (some dictionary/commentary content) | ❌ |
| Audio | ❌ | ❌ |
| Comparison tools | ✅ interleaved/column/interlinear + diff | ❌ |

✅ Open datasets (CC BY 4.0) include TTESV, TAHOT, TAGNT, TBESH, TBESG, TFLSJ, TIPNR (with **geolocations from OpenBible**), TVTMS (versification methodology), TEHMC, TEGMC — with "coming": TAGOT, TFBDB, TOTMM, TNTMM, TBCWG. ✅

---

## D) THE MODULE / RESOURCE SYSTEM ⭐

### D.1 The catalog is real, large, and **not** in the mobile app

- ✅ **706 distinct version entries** on `versions.jsp` (I counted unique `version.jsp?version=` links on the live page, fetched today). Includes Biblical Texts and Commentaries. Note this includes copyrighted texts viewable online only.
- ✅ Third-party count: *"The STEP Bible web site has 512 versions"* — Elnwood, App Store (2022). The number has grown since.
- ✅ Distributor's claim: *"additional Bibles can be downloaded in 280 languages."*
- ✅ CrossWire/SWORD ecosystem: *"Most hosted resources come from the CrossWire module library."*

### D.2 How you browse and download (desktop only) ✅

Flow, per [STEPBible_Modules.pdf](https://downloads.stepbible.com/file/Stepbible/STEPBible_Modules.pdf):

1. Launch STEPBible → opens in browser at localhost.
2. **⋮ "More" menu → "Install more Bibles…"** → **STEP Configuration** page.
3. **Left column = installed modules. Right column = available modules**, grouped by repository.
4. **Select a repository** from a list — options include **All repositories**, STEP's own **Public** and **Licensed** repositories, plus CrossWire, eBible.org and third-party SWORD repos.
5. **Sort/filter box above the list** — e.g. type "Spanish" to filter on the Language column. ✅ *This is a nice touch worth copying.*
6. Click **"+"** to the right of a module → installs; **progress bar animates in that row's cell**.
7. **"Start STEP with the installed modules"** when done.
8. **Removal** happens on the same page (left list). ✅
9. **"Install from a directory…"** for USB/SD/offline transfer — *"The directory may appear empty, but after you select it the contents will be listed."* ✅

### D.3 Capability badges — ⭐ the single best catalog idea found

✅ Every module row carries a **feature-code string**, shown *before* download, defined in the PDF as `N/A`:

| Code | Meaning |
|---|---|
| **R** | Jesus' words in Red |
| **N** | Notes and/or cross-references |
| **G** | Grammar |
| **V** | Vocabulary (hover details) |
| **I** | Interlinear |
| **S** | Interlinear for the Septuagint |

✅ Also on `versions.jsp`: an **ⓘ info glyph whose tooltip is the full copyright/licence text**, and a **licence label** (e.g. "CC BY-SA 4.0") where applicable.

**→ This is exactly what our catalog needs and MyBible does not have.** It lets a user decide "is this worth 40 MB?" before spending the bytes.

### D.4 Download size, storage management

🔶 **NOT SHOWN.** The STEP configuration documentation never mentions per-module download size, a total, or a free-space check. Given the flow described in the PDF (a "+" button and a progress bar), size is almost certainly absent. **Flagged as our biggest easy differentiator.**

### D.5 Free vs paid, in-app purchase

✅ **Zero monetization.** Verified in three places:
- App store listing: *"Everything is free. No ads or in-app purchases."*
- 📄 AppBrain: `Ads: NO`, `Price: Free to download`.
- Redistribution licence: *"It is legal to make copies of STEP and give them away freely, but you must not sell it. You can make your own collection, or download the installers and Bibles from the Download page."* ✅
- ✅ **No accounts, no sign-in anywhere.** Cookie policy is boilerplate: site-preference cookies + Google Analytics only.

### D.6 "Verse of the day" / upsell

✅ **None. Zero promotional surface.** This is clean.

### D.7 Installer distribution

✅ Per-OS installers with **explicit download-region selection (USA / Europe / Asia Pacific)** — 📄 confirmed in the STEPBible forum thread *"Download Regions (?)"*: *"It is for download speed. Especially for people with slow Internet connections."*
✅ Sizes (📄 from `dev.stepbible.org/downloads/`): Windows `.exe` ≈ 167 MB, macOS `.dmg` ≈ 197 MB, Linux `.rpm` ≈ 222 MB, `.deb` ≈ 205 MB. All four OSes, plus all historical versions retained.
✅ Keyboard/font kits (Greek + Hebrew with pointing/cantillation) shipped as separate downloads — a thoughtful majority-world affordance. ✅

### D.8 What the download experience actually feels like

🔴 **First-run indexing is a known, unresolved pain point.** ✅ Verbatim from the STEP user guide: *"When you run this the first time, it will take a long time to index everything for fast access."*
🔴 **Known bug with no root cause**, in the official FAQ: *"### STEP installed but it stopped indexing after about 70% — This is a known 'issue' with some computers, and we haven't yet pinned down the cause. Some users have found it works if you turn off the computer and try again. An Apple user said it worked after he dragged STEP into the trash and reinstalled."*
🔴 **Search silently breaks** and the documented fix is a raw localhost REST URL: ✅ *"Run the STEP software. Then click this link: `http://localhost:8989/step-web/rest/setup/reIndex/KJV`"*.
🔴 **STEP's own module repo is out of sync with its config**, open since Oct 2021: ✅ [STEPBible-Data issue #35](https://github.com/STEPBible/STEPBible-Data/issues/35) — *"ZIP filename should match with module ID in repository… Otherwise module manager does not know what to download. I'm trying to use the repository with And Bible."* David Instone-Brewer's reply: *"These are out of sync with, and older than, the modules we put in place for the Crosswire site… even our ftp service for those modules doesn't seem to be receiving requests."* **Still referenced as a live problem in a 2026 forum thread.**

### D.9 The mobile app's module story (the cautionary tale)

✅ There isn't one. But reviewers *believed* there should be, and said so:

> **"Proof of Concept?" — SonicC89:** *"This feels more like a tech demo than an app… **No option to download translations, what even is this?**"*

> **"Only two versions" — Elnwood:** *"The interface looks great, but there's are only two Bible versions, the ESV and the Chinese Union Version. The STEP Bible web site has 512 versions. Why aren't they available here?"*

> **"The website is way better" — Honna12:** *"I downloaded STEPBible expecting it to have all the features the website has (reading it in the Hebrew and Greek, commentaries, etc.) and it doesn't. I prefer to use the web version on my phone."*

> **Irod1971:** *"It only gives you 3 translations (ESV, Spanish, and Korean or some Asian language). No Bible commentaries."* 📄 AppBrain

---

## E) Sync and data

✅ **None. No account, no sync, no backup, no export.** Everything lives in browser cookies or in a saved URL. There is no cloud, no desktop companion beyond the local-server desktop app, and no mobile persistence worth the name.

🔴 This is the single most important thing STEP gets wrong for our use case, and it is worth copying *nothing* from here.

---

## F) STEPBible specifically for our use case

### F.1 Copy these ✅

1. **Capability badges in the catalog row** (R/N/G/V/I/S) — pre-download affordance, cheap to implement, high value.
2. **Two-pane install/uninstall layout** (installed left / available right) — removal is a first-class citizen of the same screen, not buried in settings.
3. **Sort/filter box over the catalog** with per-column filtering (language, type, features).
4. **Inline per-row progress bar** that occupies the row, not a modal.
5. **"+ install then 'Start with the installed modules'"** — batch-then-commit flow.
6. **"Install from a directory…"** — USB/SD/local-folder import for zero-internet users. Genuinely thoughtful for the majority world.
7. **Per-OS installer with a download-region picker.**
8. **Interleaved / column / column+diff / interlinear display modes with a draggable "master" version** governing versification.
9. **Explicit versification documentation and per-verse multi-reference handling.**
10. **Fully open, documented, CC BY 4.0 datasets + open-source client code** — `STEPBible/step` and `STEPBible/stepmobile` are on GitHub.
11. **Zero monetization, zero accounts, zero ads.** ✅
12. **Capability-gated UI**: options that don't apply to the selected module simply aren't offered.

### F.2 Avoid these 🔴

1. **Never tie the resource catalog to a different surface than the reader.** STEP's mobile app is a static DB shell while the catalog lives on the web. Users read that as "misleading" and "tech demo", and the app was pulled from Play.
2. **Don't store user data in cookies or URLs.** STEP's bookmarks evaporate on cookie clear and cannot be exported at all.
3. **Don't ship an unresolved first-run indexing step** ("takes a long time", "stops at 70%", unknown cause).
4. **Don't have users fix broken search via raw localhost URLs.**
5. **Don't let a metadata/config repo drift out of sync with the artifact repo** — STEP's has been broken since 2021 and is still referenced as broken.
6. **Don't name a companion app identically to a much larger product.** Nov 10 2024 review, verified ✅: *"having the same exact name as a suite of Bible tools with many, many more functions (which is only available on PC) is confusing… Changing the name to STEP Bible Lite or something would limit confusion."*
7. **Don't bury the value.** Discoverability is STEP's long-standing, repeatedly-cited weakness.
8. **Don't ship a catalog without sizes or licence visibility.** STEP shows licence on the web list but shows nothing on the desktop install screen.

### F.3 Verified user complaints about downloads/storage/upsell (STEP)

**There are no upsell complaints — because there is no upsell.** This is worth stating explicitly: STEP is the cleanest monetisation example of the two.

All STEP complaints are about *feature parity and stability*:

| Complaint | Verbatim | Source |
|---|---|---|
| No downloads | *"No option to download translations, what even is this?"* | App Store |
| Catalog mismatch | *"The STEP Bible web site has 512 versions. Why aren't they available here?"* | App Store |
| Search broken | *"App just searches for the keyword. Nothing else. All results out of order. Every time you click a result the search is cleared so you gotta re-search and scroll."* | App Store |
| Search broken | *"The word search… returns results that are neither ordered nor sortable."* | App Store |
| Offline broken | *"Love STEPBible but when using in 'offline' mode, it doesn't always load all of the chapters/verses and there is know option to switch out of offline mode."* | App Store |
| Content truncated | *"I have not been able to open all of 2 John. Only the first two verses appear and STEPBible freezes up."* | App Store |
| Content truncated | *"2 Corinthians chapter 7 wont load beyond the first verse."* / *"1 Corinthians chapter 1 doesn't load after verse 3."* / *"Galatians one only house to verse five"* | App Store |
| No highlighting | *"wish STEPBible developer would make it to where you could highlight certain verses"* | App Store |
| Naming | *"...confusing… should be called STEP Bible Lite"* | Play |
| No ancient texts | *"until this app has the ancient texts, it won't be very useful. I usually just use the online mobile version of STEP in my browser."* | 📄 AppBrain |

📄 Aggregate NLP scores from JustUseApp: **Safety 65.8/100, 34.2% negative sentiment** — low, driven entirely by "doesn't do what I expected".

---

# APP 2 — MyBible (Denys Dolganenko, mybible.zone)

> This is the **only one of the two** that is a genuine mobile downloadable-module app, and it is by far the more useful reference for our purposes.

## A) Reading experience

### A.1 The core layout decision — scroll only, deliberately ✅

> *"MyBible shows to you the text of a current Bible book as a scroll. **There are no text pages** in MyBible; chapters follow one another. Such an approach to presenting the Bible text is quite intentional – it allows you to put any place of a book into the center of your screen and study it in its immediate context."* ([Plain reading](https://mybible.zone/android/how-to/plain-reading/))

And under "Lacking something you are used to?": ✅ *"As it is explained at the top of this article, there are no, and not going to be, text pages to flip."*

**However**: Play Store and App Store listings say *"convenient paging and scrolling"*, and the feature list says *"all chapters of a book (not just one chapter at a time)"*. ⚠️ **CONFLICT** — the maintainer's own guide is authoritative: continuous book scroll only, plus an optional **"Single Bible chapter mode"** added in 5.7.0, pre-configured **for Psalms and Proverbs only**. ✅

### A.2 Navigation gestures — unusually good, worth stealing ✅

| Gesture | Action |
|---|---|
| Tap right half of screen / volume-down | Scroll one screen down |
| Tap left half / volume-up | Scroll one screen up |
| Horizontal swipe → | Next chapter |
| Horizontal swipe ← | Previous chapter |
| **Two-finger** horizontal swipe → | Next **book** |
| Long-tap on text | Select verses |
| Vertical fling on a header button | Reveal overflowing header buttons |

*("The volume buttons scroll Bible text" setting was later removed so volume keys can be remapped; 5.7.0 added a "Keyboard" settings category for hardware shortcuts. ✅)*

### A.3 Current-verse tracking ✅

A fixed **"Bible position button"** in the window header shows the reference of the **topmost visible verse**. It is also the jump control (tap = select position, horizontal fling = type a reference). Its width recalculates per book so the button never truncates. ✅

### A.4 Typography & themes — the most powerful in this class ✅

✅ **Appearance themes**, tuned *separately for day mode and night mode*. Each theme can carry:
- Per-UI-element font, size, colour (Interface: Colors is itself categorised)
- Per-Bible-window theme (**different theme per Bible window**)
- Bible text: spacing, margins, width, line spacing
- "Old paper" textured background (scrolls with the text, no seam artefacts)
- **Custom font support**: install `.ttf`/`.otf` into `MyBible/user/fonts`, then assign; "copy font name to all items" helper ✅
- **Theme auto-assignment** by Bible module or by language ✅
- **"Borrowing from other themes"** — inherit parts of another theme ✅
- User-submitted themes are downloadable **modules**

Built-ins ✅ (with the maintainer's own honest self-critique, which is refreshing): *MyBible original* ("This is a 'dinosaur' theme… half-light-half-dark… looks like it was made around the year of 2000" — but "most MyBible users like this theme"), *Golden compact*, *E-paper2* (for e-ink), *Jeans*, *Turquoise* and *Red Bus* (non-contrast), *Cloud* (contributed by a user). Plus a **downloadable bundle** of extra light non-contrast themes.

🔶 **No sepia.** Closest is the "old paper" texture in the default theme.

### A.5 Parallel translations ✅

- **2–8 simultaneous Bible windows** (default 3 — the settings raise the cap). ✅ *"the settings allow to increase the maximum number of Bible windows from the default 3 up to 8."*
- Windows **auto-synchronise** to the current position, **but can be decoupled and driven independently** (a "windows synchronization state" toggle).
- Optional "Use the same (widest needed) widths for module button and position button in all open Bible windows" so headers align across windows (5.8.5, off by default).
- **"Verses in different modules"** — select verses anywhere, compare how every installed translation renders them; one tap from search results. ✅ (5.8.0)
- Reading plans respect per-window sync state when advancing. ✅

### A.6 Interlinear / original-language display

🔶 **No true interlinear module type.** The MyBible module format has no interlinear type (types are: Bible, Dictionary, Subheadings, Cross-references, Commentaries, Reading plans, Daily devotions, Bundles). What exists instead:
- **Strong's numbers inline**, transliteration, and brief lexicon info — switchable. ✅
- 📄 An App Store reviewer of the iOS build praises *"an awesome interlinear option (HSB+)"* — HSB+ is a Bible module whose abbreviation suffix means "has Strong's"; 🔶 this is likely a Strong's-inline rendering, not a word-aligned interlinear. **Treat as weak interlinear at best.**
- Hebrew/Greek full text modules with pointing and accents ✅ — and the forum confirms users install **FreeSerif** for correct vowel/accent rendering. ✅

---

## B) Navigation

### B.1 Jump-to-reference — ⭐ four different UIs, all excellent ✅

1. **Full grid, zero scrolling** — all books / all chapters / all verses of the chapter rendered at once, even for the largest books. Chapter cells show verse counts.
2. **Book grid + numeric entry** combined; chapter/verse fields show the max chapter count and verse count in their lower-right corner.
3. **Book list with a lookup field** (treat it as a fuzzy search list).
4. **Typed position dialog** — type `Jn 3`, `Gen 1:10`, `1 10` (current book assumed), full book names, ALL-CAPS accepted. The **Go button only enables when the position is valid** ✅ (great validation affordance).

Plus: desired/custom **book abbreviations** per user (5.5.0), named **custom book sets** for search/bookmarks (5.8.5), long-tap to jump to book/chapter start.

### B.2 Bookmarks, notes, highlights, history ✅

| Feature | Detail |
|---|---|
| **Bookmarks** | Categorised; per-bookmark comments; comments can be **preceding** or **concluding** (5.5.0, lets a comment act as a subheading); background highlighting; side panel; sort by timestamp |
| **Bookmark sets** | Named, exportable/importable as files; overwrite-confirmation on export (5.8.1) |
| **Remarks** | Verse-anchored notes with **auto-hyperlinking** of typed references (type "John 3:16" → tappable link); balloon display |
| **Reading places** | Quick-jump slots |
| **History** | Navigation history, grew 30 → 40 (5.8.1) → **100** (5.8.5); chapter jumps recorded |
| **Profiles** | Complete environment snapshots — settings, themes, navigation history, module sets. Lets you keep "My readings", "1Cor 13 lesson", "Today's sermon" as separate environments |
| **Memorize** | Flashcard/memorisation engine (repetition exercises, word-ordering, voice), overhauled 5.7.0 |

### B.3 Reading plans ✅ (a full module type)

78 pre-defined plans (count as of the 2021 guidebook ✅). Multiple plans active simultaneously. Custom simple plans. Progress tracking, **auto-mark-as-read on scroll** (with a setting to auto-advance to the next item), long-press to toggle an item's completed state, clear-the-read-mark. Fixed several times: plan items spanning multiple chapters, adjacent-day duplicates, Psalms/Proverbs in single-chapter mode.

### B.4 Search — the feature users praise most ✅

Extremely rich, documented in full at [mybible.zone/android/search](https://mybible.zone/android/search):

- Word-fragment search; `*` any-run wildcard; `_` single-letter wildcard
- Exact phrases in `"…"`; double the quote to search for a quote character
- `~term` exclusion; `+N` max verse distance between words (overcomes artificial verse boundaries)
- Boolean `&` / `|` / parentheses for combining fragments
- Inline setting overrides typed into the query: `+w` `+r` `+a` `+c` `+q` `+j` (Jesus' words only) `+i` (translator-inserted words only) `+h` (only your highlights) `+m` `+s` (show Strong's) `+v` (one row per verse across modules)
- Restrict to book sets; search **your own highlighting** by colour/underline type
- Search **across multiple Bible modules** via module sets, with per-set ordering
- Search Strong's numbers directly (5.8.4)
- Search **inside** commentary / dictionary / devotion articles (5.8.0)
- A dedicated **Search help** page shipped in-app

📄 Verbatim user praise: *"The number one thing I use it for is the search function."* *"The search feature is one of the best available."* ✅

⚠️ Complexity cost: every fix to search got a release-note entry (quoted-phrase search breaking on Strong's modules, highlighted verse numbers poisoning results, `+h` being slow, morphology missing from results). **Search across many modules is fragile.**

---

## C) Study tools ✅

- **Cross-references** (14 modules; default RST-x) — inline `⇅[n]` links after verses; tapping a **verse number** opens a *much larger* cross-reference window; filterable by typed fragment ✅
- **User-defined cross-references** ✅
- **Footnotes** — live *inside* Bible modules, so they download/delete with the text ✅ (a smart packaging decision)
- **Commentaries** (100+ English) — in a window (3 presentation modes: single article / combined per mode / combined per Bible position) or in a **balloon**; **commentary hyperlinks embedded in the Bible text**; **per-Bible-book commentary assignment**; **comparison of multiple commentaries** on a verse
- 🔴 **"MyBible does not support reading of commentaries 'as a book' – throughout. It only supports reading of separate commentary parts/articles for the currently shown Bible place."** ✅ (deliberate, stated)
- **Dictionaries & lexicons** (84 English) — double-tap a word to open; word-forms dictionaries map inflections to headwords (auto-pulled when you select a dictionary for a language); **cognate Strong's**; variant-to-lexeme mapping; "look up references to a selected verse from dictionary articles"; dictionary *word* search; favourites
- **Strong's usage search** — replaces a printed concordance; history of accessed Strong's numbers
- **Maps** ✅ — dictionary modules containing **scanned map images plus JavaScript** with zoom and tap-to-fullscreen; bind a circular gesture to "search only in dictionaries" and a toponym jumps straight to its map
- **Subheadings modules** — decoupled from the Bible text module (portable across translations)
- **Daily devotions** (32 English) — series with assignable start date, per-date navigation
- **TTS** — Bible text, commentaries, dictionary articles, devotions; **auto-chains commentary audio into the text audio**; lock-screen notification with pause/resume/cancel; chapter-count limit; selectable engine; pause on phone calls; max inter-verse pause raised to 200 s
- 🔴 **No audio narration, ever.** ✅ Developer reply, verbatim: *"Hold on to that star — **MyBible will never contain audio materials narrated by professional actors, for a number of reasons.**"* Result: a 1-star-withheld review *"I'm keeping a star from you till you add that one."* ✅

---

## D) THE MODULE / RESOURCE SYSTEM ⭐⭐ (the most important section in this report)

### D.1 What a module *is* ✅

**Modules are SQLite3 databases.** Verbatim from the format spec:

> *"General — MyBible Android application has downloadable modules which are SQLite databases, containing several tables and indexes for them. On a PC, MyBible modules can be opened and edited using freely available SQLite browsers."*

- File naming: `ABBR.SQLite3` where the suffix encodes the type: `.dictionary`, `.subheadings`, `.crossreferences`, `.commentaries`, `.plan`, `.devotions`; a trailing `+` in the abbreviation (e.g. `KJV+`, `BSB-19`) = has embedded Strong's numbers
- Every module has an `info (name TEXT, value TEXT)` table of name/value config pairs
- Per-type tables: `verses`, `books_all` (`is_present` flag lets a translation declare partial books — this is how partial / apocryphal / non-canonical texts work), `dictionary`, `words`, `cognate_strong_numbers`, `xrefs`, `commentary`, …
- **Zipped modules**: `<suffix>.zip` containing `<suffix>.SQLite3` — the convention exists specifically because *"on many Android devices a built-in ZIP library does not support national characters in filenames within a ZIP."* ✅ **Steal this trick if we ship non-Latin module names.**
- **The format is public and documented** (a "MyBible Modules Format" document, revised over time), and there is an active "for doers" page on module authoring. ✅

### D.2 The catalog is registry-driven ✅

> *"In the MyBible system, the list of available modules is maintained in the cloud (on several diverse file hosting servers) as a **'module registry'**. The MyBible app downloads this registry."* ([Extra module registries](https://mybible.zone/android/tips/modules/extra-registries/))

The cached registry file is `persisted_registry.json`, living at `/Android/data/ua.mybible/files/MyBible/persisted_registry.json` (named explicitly in the Aug 2024 incident write-up). ✅

✅ **5.8.4 improvement:** *"When a module is downloaded, its description and additional info, shown in the list of modules, are taken from the downloaded module rather than from the registry."* — i.e. the registry is only a *pointer*, and the module is the source of truth once fetched. Good design.

### D.3 The catalog screen ✅

Menu → **Modules**. Structure, from the guidebook walkthrough:

```
Bundles                              (no-text bundles at top; language-agnostic)
English - Bible Modules          ›   (expandable category)
English - Dictionaries          ›
English - Subheadings            ›
English - Devotionals             ›
English - Commentaries           ›
Cross References                 ›
Reading Plans                    ›
Original - Dictionaries         ›
Original - Bible Modules         ›
Ancient Greek - Bible Modules    ›
```

**Filters** ✅: radio buttons along the bottom for language (`English`, `All languages`, …) and **`My`** (= already downloaded).

**Per-row** ✅:
- Abbreviation (with `+` suffix badge meaning "has Strong's")
- Title — **tap the down-arrow to expand a full description before downloading** ✅ (this is a real preview!)
- A download icon on the right; tapping it selects (turns grey)

**Batch flow** ✅: select as many as you like → toolbar **Download** icon → **Download** → *"A few modules will download at a time, and you will see the newly blank space on the right fill with a progress line as they are being downloaded, and they will become a Tick icon when completed."*

**Bundles** ✅: curated multi-type selections (texts, fonts, appearance themes) in one download. Example shipped in the registry: *"Holy Words Of God — Every Verse in 32 essential subjects."* Bundles with no texts sit at the top of the list because they're language-agnostic.

### D.4 Module states ✅ — three, explicitly documented

> *"There are three possible states of a module: **available for downloading**, **downloaded**, and **local only** (not available for re-downloading). **If there is no Internet connection, all your modules will appear as local only.** Select modules by tapping them, then use buttons on the selection mode bar to manipulate them."*

**Updated modules** get a distinct highlight ✅: *"A module will appear highlighted with a different color, if: a module was updated having a language which MyBible thinks you can potentially use; you did not (re-)download a module after it was updated."*

🔴 **The offline behaviour is bad.** Going offline reclassifies *everything* as "local only", including modules you never downloaded — and "local only" reads as "not re-downloadable", which is a lie about modules you don't have. Don't copy this.

### D.5 Automatic updates ✅

*"The application supports automatic updating of already downloaded modules and lets you update modules manually if desired — using the Internet connection."* Users are told to *"Consider enabling automatic module updates in MyBible settings."* Extra registries are re-fetched on every visit to their settings page (5.8.5). ✅

### D.6 Dependency auto-selection ✅ ⭐

Selecting a dictionary for a language **auto-selects the matching word-forms dictionary** — ✅ *"For the dictionary lookup to work effectively, MyBible needs a word forms dictionary for the text language. MyBible will automatically select for downloading a corresponding word forms dictionary when you select for downloading a dictionary for a particular language."* Auto-**de**selection was added too (5.7.0), after the mechanism was accidentally broken in 5.6.0. **Copy this.**

### D.7 Third-party registries — ⭐⭐ the best idea in this whole report

Added in **5.5.0** (Nov 2022) ✅. Verbatim:

> *"The **'Extra module registries'** menu item in the Modules window lets you control your list of extra module registries. In order to add an extra module registry you need to know a downloading URL for the extra module registry file… Once an extra module registry is added on your device, modules from it become available **in the common list** in the Modules window and **can be used just as modules maintained by the MyBible team**, including automatic updating… Such extra modules have **different status icons – with an asterisk in the upper left corner**."*

Flow: get a URL → copy to clipboard → Modules → Extra module registries → paste URL → enable auto-updates.

**Why this is the model for a "public catalog" app:** it lets **anyone** publish modules to **any** user, with per-registry visual provenance (the asterisk), auto-update, and **zero privileged infrastructure**. The stated motivation is worth quoting: *"a periodic update of modules on the end users' devices, requiring a not-straight-forward manual procedure, quickly becomes an irritating burden."*

### D.8 Sideloading / import ✅

- **Drop the file into the data directory** — *"MyBible automatically picks up a module if it is placed to the MyBible data directory on the device."* (Noted as not-one-tap since Android 11 moved that directory deep into private storage.)
- **Tap the file in a file manager** → import dialog (5.5.0). Recognised types: Bible / dictionary / commentary / cross-reference / devotion / reading-plan / subheading modules, plus themes, profiles, bookmark sets, desired abbreviations.
- 🔴 **Register-as-handler bug worth learning from:** 5.5.0 made MyBible react to *all* file types; users asked *"why does MyBible interfere with my starting MP3s from the file manager?"*; 5.6.0 narrowed it to `*.json` and `*.zip`. ✅ **Don't claim broad file-type intent filters.**
- **Import `.zip`** — most Android file managers auto-unzip zips, so users must use "Open with" or the system Files app. ✅ (acknowledged papercut)
- **Pre-installed-module APKs**: official `ru pack` / `uk ru pack` builds distributed over **Bluetooth or WiFi Direct** ✅ — *"One can use MyBible installed from such an installation right away, without a need to download modules and thus without a need in Internet connection."*

### D.9 Download size, storage management 🔴

**No evidence of any of the following, anywhere in the docs, tips, or 7,800 lines of release notes I grepped:**
- per-module download size shown in the catalog
- a running total for a multi-select batch
- a free-space check before starting a batch
- a "storage used by MyBible" figure

I grepped the release history for `module.*size`, `free space`, `disk space`, `storage` and found only unrelated hits (Android 10 storage-permission requests, a legacy `/fonts` path). **Treat this as a strong negative: MyBible's catalog has no size information at all.** This is our clearest opportunity.

The *only* size-adjacent guidance anywhere is in a community guidebook ✅: *"Install a maximum of 20 Commentaries to keep the app fast and efficient when searching them."* — i.e. **performance advice is outsourced to a user-written PDF.** 🔶

### D.10 Deletion ✅ / 🔶

Verified: removal happens from the Modules window via the selection-mode bar (*"Select modules by tapping them, then use buttons on the selection mode bar to manipulate them"*). Footnotes delete with their Bible module ✅. 🔶 The exact delete affordance and any confirmation/size-reclaimed feedback is not documented in the tips — **unverified detail**.

### D.11 Free vs paid ✅ — and philosophically interesting

✅ *"Everything about MyBible is free – the MyBible project is intentionally not connected with money in any way. The MyBible team deliberately **does not accept donations**. There are no ads in the app, and not going to be."*
✅ Google Play data safety: **No data collected. No data shared with third parties.**
✅ Goals page: *"Financial gain"* is explicitly listed under **NON-goals**.

The rationale page is unusually thoughtful and directly relevant to a no-IAP app ✅:
> *"Thirdly, since I am the author of this project, I do not want to lose my freedom to decide what and how to do… Fourthly… I consider this labour to be my ministry and do not want to mingle it with money in any way."*
> And the copyright-pressure anecdote: *"When we have started negotiations on free publishing of copyrighted texts in our modules, one pastor from Australia… had advised us to remove mentioning of donations from this site, **so that Bible societies could have no grounds to question purity of our intentions**."*

**This is the reputational hygiene argument for never monetising: it protects the project's credibility with rights-holders.** Directly applicable to us.

### D.12 "Verse of the day" / upsell ✅

- ✅ **No verse of the day and no promotional surface.**
- **Random verse** instead ✅: header button + menu item; long-press configures it — pick book(s), or request "first verse of a random chapter".
- **Daily devotions modules** (32 English) are content, not promotion.
- A **home-screen widget** exists ✅ (widget titles are configurable per module; a Psalms `%s` bug was fixed in 5.6.0).
- Verbatim 5.7.0: the app added assistance *"for beginner MyBible users thinking/exclaiming things like 'only KJV? no other Bibles??'"* — see D.13.

### D.13 ⭐⭐ The "[More]" pattern — copy this verbatim

MyBible 5.7.0 added, at the end of **every** module-selection dropdown:

> *"At the end of module selection dropdown lists provided the item **'[More]'**, accessing the 'Modules' window to download more modules. A new setting **'Show the [More] item…'** at the end of the Display settings category allows to hide the above item — for users not needing such a reminder/shortcut."*

This is a **persistent, unmissable, contextual path from any "which translation am I reading?" moment into the download catalog**, plus a user-controlled off-switch. It is a direct answer to the classic module-app failure mode. Also in 5.7.1: **"Select all" / "Select none"** buttons for expanded groups of modules ✅.

### D.14 The "quick-select + module sets" pattern ✅ — also copy

> *"If you have more than a few Bible modules downloaded, perhaps some for a frequent use and others just for an occasional checking, having a long list of Bible modules to choose from takes some extra moments… MyBible allows to limit the immediately shown modules using a long-tap on the Bible module button."*
> …**"quickly selectable"** modules as a checklist grouped by language; the rest one tap away under **`[All]`**; and **named Bible module sets** with user-defined order.

Solves the "I downloaded 100 translations, now I can't find anything" problem without deleting anything.

### D.15 Catalog size ✅ (with a date caveat)

From the community guidebook (current version cited 5.7.1, so the counts are ~2021) ✅:

> *"Over **3,000 module downloads**… over **200** translations of the Holy Bible in English; The Holy Bible in **over 800 different Languages**; **14** different Bible Cross Reference modules; **84** different Bible Dictionaries in English; **32** different Bible Devotionals in English; Over **100** Bible Commentaries in English; **78** different Bible Reading Plans."*

App-store marketing says "more than three hundred languages" (Google Play) and "hundreds of translations" (App Store) — ⚠️ **slight CONFLICT** with the guidebook's 800 languages; the guide is probably counting partial texts, the store copy rounding down. 🔶 The registry has certainly grown since 2021. 🔶

### D.16 What the download experience feels like — verified failure modes 🔴

**The single worst incident, and it is a great lesson:**

🔴 **25 Aug 2024 — the registry broke downloads for everyone.** ✅ Verbatim from the developer's own post:
> *"Due to recent manipulations with the MyBible modules registry (adding of another hosting server and the follow-up re-generation of the registry), a MyBible defect that wasn't noticed until recently can cause a mistaken message that the MyBible modules registry does not function, and a subsequent inability to download modules. The problem in the MyBible code has already been fixed… In order to overcome this problem with the current version: 1. Connect your device via a USB cable to a PC or Mac… 2. navigate to `/Android/data/ua.mybible/files/MyBible`. 3. **Find and delete the file `persisted_registry.json`**"*

**The required support action was: USB cable + file manager + manually deleting a JSON file.** A routine catalog-metadata change bricked the entire module system. Two mitigations shipped later:
- **5.6.0:** *"When there is a current modules registry downloading problem, updating and downloading of modules (per the last successfully downloaded registry) is **no longer blocked**."* ✅ — **copy this: cached-manifest fallback.**
- **5.7.0:** *"Prevented the MyBible 'Downloading…' notification staying indefinitely in case if MyBible cannot reach any of the registry host servers."* ✅ — **copy this: bounded retries + a terminal state.**

Other verified download pain:
- **Host-server dependency is structural.** The registry lives on *"several diverse file hosting servers"* (Dropbox-linked, per the APK URLs) and the hardcoded server list needed updating repeatedly — including on iOS: *"To the list of hardcoded MyBible registry servers added an existing server that was missing there"* and *"Updated built-in addresses of the Modules Repository servers, to point only to the currently functional servers – to enhance the modules downloading performance."* ✅ **Fragile. Don't hardcode a small host list.**
- **Android 4-specific download bug** required a special legacy build (5.3.3.1) that could not go through Play. ✅
- **Play-only release gated fixes for days:** *"MyBible 5.8.0… has been sent to Google Play. Its processing at Google and publishing might take a few days; meantime, the version is already available at the downloads page."* ✅
- 🔶 No evidence of per-module size display ⇒ **a user picking 100 translations has no idea what they're committing to.**

---

## E) Sync and data ✅ — and it is the weakest area

✅ **No account. No telemetry. No built-in sync.** The maintainer is explicit that Google Drive integration was considered and declined:
> *"The app developer realizes the use convenience of this option. There are obstacles to its implementation; the main one: **the app developer does not need this himself**, as existing options below are enough."*

Three documented paths:

1. **Zip export/import** ✅ — Settings → **"Send data…"**; since **5.8.5** it can optionally **include downloaded modules**; sent via Android share sheet (Telegram/Drive). Import by tapping the `.zip` in a file manager. Import dialog lists all files that will be imported (5.8.1) and preserves folder hierarchy for notes (5.7.0).
2. **Third-party file sync** ✅ — DropSync / Drive Autosync, two-way, syncing the data directory.
3. **USB copy** of `/Android/data/ua.mybible/files/MyBible` ✅

🔴 **The documented gotchas are severe and are a direct warning to us:**

- *"It takes a noticeable time to zip up all the data, especially if you have a lot of downloaded modules. Also, that there is **no automatic periodicity** — you need to do this manually from time to time."*
- *"**Free versions of files synchronization apps limit uploading to the cloud to several megabytes**, so they will not synchronize big MyBible modules. If you cannot afford spending a few dollars on a paid version… synchronize only the `MyBible/user` subdirectory, and when restoring lost data manually download the modules."* → **sync is effectively a paid feature**
- 🔴 **Android 13 killed the recommended sync path:** *"Since on Android 13 the access to an app's private data directory has been prevented for file managers and similar apps (e.g. Dropsync), **the suggested way of synching MyBible data no longer works**."* The workaround is an unofficial **"X installation"** APK (declares Android 10 compatibility) that lets you move the data dir back to `/MyBible` at storage root.
- 🔴 **Conflicts are destructive and unhandled:** *"MyBible updates its settings file rather often, so with parallel usage of MyBible on several synchronized devices the synchronization of MyBible settings **practically does not work**… the latest update of the file will then stay, **completely overwriting** the update made earlier from another device. Also, additional files will be created, having the word 'conflict' and timestamp info in their names (such files can usually just be deleted)."*
- 🔴 **Uninstalling destroys everything.** 5.4.0 moved data into app-private storage, so the maintainer had to publish a warning: *"**All the MyBible's data are being automatically deleted if you uninstall MyBible, so think about possible losing of your data, do not rush to uninstall MyBible freely as you were able to before.** So it is especially important to set up MyBible data synchronization."* ✅

**Desktop/web companion:** 🔶 **None native.** Officially: *"There is no MyBible developed specially for a PC – such an app is not in our plans."* Community routes: Android emulator (guides for Windows/Linux/Win11), or `scrcpy` screen-mirroring from a real device. iOS runs on Apple Silicon Macs. ✅

**Version strategy (good):** every APK from 4.0.0 onward is downloadable from the website, plus "X builds" and pre-installed-module packs. ✅

---

## F) MyBible specifically for our use case

### F.1 Copy these ✅ — this is the blueprint

1. **Modules = SQLite3 files with a published, versioned format spec.** Public spec + a "for doers" module-authoring guide + a community of module makers.
2. **Registry = a small cached JSON manifest** describing what's available; **fetch the module, then read metadata from the module**. Registry is a pointer, not a source of truth.
3. **Cached-manifest fallback** — a broken/unreachable registry must never block downloads. (Learned the hard way, Aug 2024.)
4. **Bounded retries + a terminal "download failed" state.** No immortal progress notifications.
5. **Third-party registries via pasted URL**, merged into the one catalog with an **asterisk provenance badge** and auto-update. *This is the killer feature for a public-catalog app.*
6. **File-drop sideloading + tap-to-import**, plus **pre-installed-module builds** shared over Bluetooth/WiFi Direct for true offline users.
7. **Capability badges** (`+` = Strong's) and **tap-to-expand descriptions before download** — MyBible has the preview, STEP has the badges; **combine both**.
8. **Bundles** — curated multi-type downloads for onboarding ("Every Verse in 32 essential subjects", "default modules for your UI language").
9. **Dependency auto-selection + auto-deselection** (word-forms dictionary for a chosen dictionary language).
10. **"[More]" item at the bottom of every module dropdown**, with a user off-switch.
11. **Three explicit states + an "updated, re-download?" highlight.**
12. **Quick-select subset with an `[All]` escape hatch; named, ordered module sets.** Never force deletion to tame a long list.
13. **Auto-update of downloaded modules, toggleable.**
14. **"My"/downloaded filter + language filters.**
15. **Per-window themes, per-window sync toggles, 2–8 windows.**
16. **One-tap export of user data as a plain `.zip`, importable by tapping it.**
17. **Zero accounts, zero ads, zero donations, zero telemetry** — and *publish the reasoning*. The rights-holder-credibility argument is a genuine strategic asset.
18. **A published, honest "how to" guide** (dozens of articles) and in-app searchable usage tips. Also a first-class "Too much of everything!" article that treats complexity as the user's problem to solve by *removing* things (hide menu items, hide header buttons, uncheck display options).
19. **Every screen's chrome is user-configurable** — hide/reorder main menu items, header buttons, and per-window display options.
20. **Deep-linkable, shareable app state** on web (STEP does this well; MyBible does not).
21. **Regression-test gate before release.** MyBible 5.6.0 shipped and bricked startup for users until 5.6.1.

### F.2 Avoid these 🔴

1. **Never make user data vanish on uninstall.** MyBible had to publish a "do not uninstall" warning. Ship at least local scheduled backups, and make the backup state visible.
2. **Never make backup/sync depend on a third-party app, a paid tier of that app, or a directory the OS locks.** MyBible's recommended sync path died on Android 13 and the workaround is an unofficial APK. This is the single most-cited weakness in its reviews.
3. **Never advertise a feature you then refuse on principle without saying so prominently.** The "no professional audio, ever" stance produced a withheld star. *(We can afford to be principled — just be explicit in the catalog: "Audio modules: not supported".)*
4. **Never let registry metadata be load-bearing.** One JSON regeneration bricked all downloads; the support fix required a USB cable.
5. **Never hardcode a short list of host servers.** MyBible's list needed repeated patching even for iOS.
6. **Never gate a bugfix behind a Play review.** 5.8.0 sat on the website for days because of Google processing; a legacy-Android download fix could not be delivered at all.
7. **Never let the catalog imply re-downloadability when you're offline.** "All modules appear as local only" is misleading.
8. **Ship sizes.** Neither app shows per-module size, batch total, or free space. Do it.
9. **Warn about performance in-product, not in a fan PDF.** "Max 20 commentaries to keep the app fast" belongs in the catalog UI.
10. **Don't let module count silently degrade search.** Release notes are full of search regressions introduced by added modules. Cap/warn.
11. **Don't claim broad file-type intent filters.** The MP3 incident.
12. **Don't ship two divergent apps under one name.** The iOS app is "significantly less functional", was dead 2018→2022, and 3.0.2 shipped untested and **crashed on launch for every upgrading user** ✅ — *"Our bad – a rough start after four years of the app being 'dead'… we simply did not test it enough, having not expected any surprises from the source code that was working decently for years."* The recovery included assembling a remote TestFlight test team.
13. **Don't call an app "Interleaved"-only, or omit "books" and apologise.** The absence of a Books/Atlas module type is MyBible's longest-standing community complaint (2016 → still quoted): *"Only thing I don't like MyBible is its lack of book modules. I must keep e-Sword or MySword for many beautiful bible Atlas."* Maps partially fill the gap now.
14. **Don't mistake complexity for depth.** Both apps suffer discoverability cliffs; MyBible's official remedy is a reading list. Design progressive disclosure into the first-run experience instead.

### F.3 Verified user complaints about downloads / storage / upsell (MyBible)

**No upsell complaints. Zero.** Consistently praised as the opposite:
> *"I searched and downloaded several of the more popular Bible apps only to find advertisements. **This one has No Ads** and is the most customizable."* — Prodigal Returned ✅
> *"Still the best Bible app out there! Some people are complaining for the lack of popular translations, but that's not the developers fault. The problem is with the Publishing Companies that copywrite God's word…"* ✅
> *"it's one of the best out there as it loads fast and **there's no ads**"* — Artnerd1524 ✅

The actual complaints:

| Theme | Verbatim | Source |
|---|---|---|
| **Catalog appears empty** | *"When I open MyBible, nothing appears. I've tried to download modules, but still nothing shows up. I've uninstalled and reinstalled this app 3 times. Has anyone else had this issue? **Why won't any translations show up as available for download?**"* | App Store, 2022-04-27 |
| **Wanted translations absent** | *"there used to be many versions of the Bible available but for some reason now many say **'removed for potential copyright issues'**"* | App Store |
| **Export/import broken** | *"I have increased my rating from **2 to 4 stars because now the app's export and import features work satisfactorily**. It's an excellent app! **An automatic syncing capability would earn it a full 5 stars.**"* | Play, 2026-08-25 |
| **Data loss** | *"When I downloaded the latest update (end of Feb,'23), **I lost ALL of my bookmarks!** I've spent years building up verse searches and am devastated… [resolved]"* | Play |
| **Missing feature cost a star** | *"But it's baffling that I can't download and listen to some dramatised audio… **I'm keeping a star from you till you add that one.**"* | Play, 2026-06-09 |
| **Wanted a login for cross-device** | *"Could you have login de usuário para guardar as configurações e marcações do texto bíblico, carregando em todos os dispositivos instalados."* | App Store |
| **iOS gaps** | *"this is an awesome tool to leave by the wayside — Please update"* / *"braкує того функціоналу, який є доступний на версії для android… Чи плануєте розширювати функціонал?"* | App Store |
| **Content bugs** | *"even though I have the latest version of the application, I still have incomplete verses"* | App Store |
| **Learning curve** | *"took me quite a time figuring it out… it's for the curious and inquisitive type of people. The customisations is may be a bit complicated but I love it all the same."* | Play |
| **Catalog gaps by language** | *"where is Georgian Bible modules?"* / *"I have request if possible try to add amplified version of Tamil bible."* | App Store / Play |

📄 Aggregate: Play **4.7★ / 40.5K reviews**; AppRecs **4.8★ / 43K ratings / 1M+ downloads**, ratings breakdown 91% 5★ (AppRecs flags **33/100 review-manipulation risk** — treat the extreme positivity with some caution). iOS App Store is much weaker: **4.6★ / 264 ratings**, and JustUseApp's NLP of 268 iOS reviews reports **52.1% negative** sentiment (driven by "no downloads showing", "incomplete verses", missing features) vs 44.9% positive.

---

# 3. Consolidated recommendations for our app

### 3.1 The pattern to build on (both apps converge on it)

```
Public manifest (JSON, cached, validated)
        │
        ├─► Catalog UI  ──► grouped by language → type
        │      • capability badges (STEP's R/N/G/V/I/S)
        │      • tap-to-expand preview (MyBible)
        │      • ★ SIZE + licence + "already downloaded" (neither has size)
        │      • "My" filter, language filters, search
        │      • multi-select → batch download with per-row progress
        │      • Bundles for onboarding
        │      • dependency auto-select
        │
        ├─► Third-party registries via pasted URL  ← MyBible's extra registries
        │      (merged into the same catalog, asterisk = third-party)
        │
        ├─► Sideload: file-drop + tap-to-import + pre-installed-module build
        │
        └─► Per-module auto-update, "updated, re-download?" highlight
```

### 3.2 Twelve concrete fixes, ranked

| # | Do this | Because |
|---|---|---|
| 1 | **Show per-module download size, a running batch total, and a free-space check before starting a batch** | Neither app does it. It's the #1 storage complaint category in this genre and a pure differentiator. |
| 2 | **Cached-manifest fallback + per-module direct fetch that doesn't require the manifest** | MyBible's Aug 2024 registry regeneration bricked all downloads; support answer was "USB + delete a JSON file". |
| 3 | **Bounded retries + explicit terminal "couldn't reach the catalog server" state with retry** | MyBible's "Downloading…" notification hung forever on unreachable hosts. |
| 4 | **Third-party registry URL support with a provenance badge** | MyBible's single best idea; lets a public catalog scale without privileged infrastructure. |
| 5 | **A persistent "[More]" entry at the bottom of every module dropdown, with a user off-switch** | MyBible added it deliberately to kill the "only KJV?!" reaction. Cheapest possible discoverability fix. |
| 6 | **User data must survive uninstall** (automatic local rolling backup + visible backup state + one-tap zip export) | MyBible had to tell users not to uninstall; its #1 recent reviewer says auto-sync would make it 5 stars. |
| 7 | **First-party backup export/import, importable by tapping a file** | Already works well in MyBible; the "now works, would be 5 stars with sync" review proves the demand. |
| 8 | **If you ever add sync, own it end-to-end** — or don't ship it. Never delegate to a third-party sync app in a directory the OS locks | MyBible's documented path broke on Android 13 and conflicts silently destroy settings. |
| 9 | **Ship a sidebar install/uninstall screen; per-row capability badges; tap-to-expand preview; Bundles; auto-select dependencies** | Direct borrow from STEP + MyBible. |
| 10 | **Quick-select subset + `[All]` + named ordered sets, so long libraries stay usable** | MyBible's answer to "I downloaded 100 translations". |
| 11 | **Do not name the companion app the same as anything bigger; regression-test before every release** | STEP's naming confusion; MyBible 5.6.0 bricked startup and iOS 3.0.2 crashed every upgrader. |
| 12 | **Publish the module format spec, keep it versioned, and ship a pre-release test channel + a "reset catalog" in-app escape hatch** | Both apps have open formats; MyBible's iOS recovery used a remote TestFlight team. |

### 3.3 Licensing notes relevant to "everything free and open-licensed" ⚠️

- ✅ **STEPBible-Data is CC BY 4.0**, with the source code of stepbible.org also open. Requirements: credit as "STEP Bible" linked to stepbible.org; record and publish any changes; mirrors welcome if kept up to date with a link back. It includes Bible modules usable in any SWORD-compatible software.
- ⚠️ **CONFLICT:** an academic paper on the project states the newer datasets *"will all be made available on public licence **CC BY NC-ND 4.0**"*, which is **not** open-licensed in the OSI sense and is incompatible with "everything open-licensed". Source: [Tyndale STEPBible Data development for machine analysis and computational linguistics](https://tidsskrift.dk/hiphilnovum/article/download/142739/186441/311522). **Verify per-dataset before depending on any of it.**
- ✅ MyBible provides only **non-copyrighted (public domain)** translations and dictionaries, converted to the MyBible format. Modules people sideload are **explicitly not endorsed** — the guidebook warns *"they are not officially endorsed by the MyBible developers."* This "unofficial content is the user's own problem" posture is a reasonable pattern, but our version should label sideloaded/third-registry modules clearly and keep them segregated.

### 3.4 Features worth stealing that neither app has

- **Per-module download size + batch total + free-space guard.**
- **Storage dashboard**: total used by modules, by type, largest 10, one-tap "clean up unused" (keeping user data).
- **Conflict-free sync**, or at minimum a merge that never silently overwrites settings.
- **Version-pinned module downloads** so a bad module update can be rolled back to the previous version locally.
- **A true word-aligned interlinear** as a first-class module type (neither app really has one; MyBible's is Strong's-inline at best).
- **A "Books" module type** (illustrated theology, atlases, photo galleries) — MyBible's longest-standing unmet request.
- **Progressive disclosure**: both apps require a user to read a guide. Ship a 60-second interactive tour that *teaches the catalog*, not the whole feature set.

---

## 4. Source list (primary first)

**STEPBible**
1. https://www.stepbible.org/ — live app
2. https://www.stepbible.org/versions.jsp — 706 version entries counted
3. https://www.stepbible.org/downloads.jsp — installers, regions, "280 languages"
4. https://downloads.stepbible.com/file/Stepbible/STEPBible_Modules.pdf — install/remove, repositories, R/N/G/V/I/S codes, filter, USB
5. https://stepweb.atlassian.net/wiki/spaces/SUG/pages/9797667/Bible+Displays
6. https://stepweb.atlassian.net/wiki/spaces/SUG/pages/8323078/Frequently+Asked+Questions — 70% indexing bug, localhost reIndex
7. https://stepweb.atlassian.net/wiki/spaces/SUG/pages/9797657/Resources
8. https://stepweb.atlassian.net/wiki/spaces/SUG/pages/9797699/Personalising — **stub: "TODO"**
9. https://stepbibleguide.blogspot.com/p/display.html — versification, comparison mechanics
10. https://stepbibleguide.blogspot.com/p/personal.html — **bookmarks in cookies**, Chrome search engine
11. https://stepbibleguide.blogspot.com/p/notes-and-references.html
12. https://stepbibleguide.blogspot.com/p/user-quotes-and-ideas.html
13. https://stepbible.org/html/cookies_policy.html
14. https://stepbible.github.io/STEPBible-Data/ — CC BY 4.0, dataset list
15. https://github.com/STEPBible/stepmobile — Expo app, prebuilt `bible.db`
16. https://github.com/STEPBible/STEPBible-Data/issues/35 — registry/artifact desync, open since 2021
17. https://groups.google.com/g/StepBibleForum — "Download Regions (?)", "Installing Bibles into Downloaded Version", "How to install LSJ"
18. http://www.crosswire.org/pipermail/sword-devel/2017-January/044076.html — STEP Public/Licensed repos
19. https://dev.stepbible.org/downloads/ — installer sizes
20. https://www.appbrain.com/app/step-bible-scripture-tools-fo/com.tyndale.stepbible — **Play removal 2024-11-10**, 33K installs, 4.31★/110
21. https://justuseapp.com/en/app/1476903313/step-bible/reviews — iOS reviews
22. https://step-bible.appstor.io/ and https://step-bible-ios.soft112.com/ — iOS 3.0.13/3.0.14, changelog, 188.5 MB
23. https://learnofchrist.com/resources/stepbible — third-party critical review

**MyBible**
24. https://mybible.zone/ — no donations, no ads, offline-after-download
25. https://mybible.zone/goals/ — explicit non-goals incl. "Financial gain"
26. https://mybible.zone/no-donations/ — the rights-holder credibility rationale
27. https://mybible.zone/android/app/ — feature list, three app icons (cross / Star of David / none)
28. https://mybible.zone/modules/ — module types
29. https://mybible.zone/android/tips/modules/modules/ — grouping, no internet needed, auto-update
30. https://mybible.zone/android/tips/modules/modules-manipulation/ — **three states**, selection bar
31. https://mybible.zone/android/tips/modules/updated-modules/ — yellow highlight rule
32. https://mybible.zone/android/tips/modules/bundles/
33. https://mybible.zone/android/tips/modules/bible-modules/ — footnotes ship inside Bible modules
34. https://mybible.zone/android/tips/modules/extra-registries/ + /android/extra-registries/ — **third-party registries**
35. https://mybible.zone/android/tips/main/maps/ — maps as dictionary modules w/ JS
36. https://mybible.zone/android/tips/main/daily-devotions/
37. https://mybible.zone/android/tips/main/random-verse/
38. https://mybible.zone/android/tips/ — full tip index
39. https://mybible.zone/android/how-to/plain-reading/ — **no pages, by design**; 4 position UIs; module sets
40. https://mybible.zone/android/toomuch/ — complexity remedy
41. https://mybible.zone/android/themes/ — theme details + maintainer's self-critique
42. https://mybible.zone/android/night/
43. https://mybible.zone/android/search — complete search spec
44. https://mybible.zone/android/synchronization/ — **all sync caveats**
45. https://mybible.zone/android/releases/ — 7,800 lines; "[More]", MP3 incident, Android 13, markup DB corruption, first-run indexing failures
46. https://mybible.zone/modules-problem-2024-08-25/ — **the registry incident**
47. https://mybible.zone/android/blog/ — release commentary, Android 4 build, spam-attack on ratings
48. https://mybible.zone/android/download/ — ~80 APK builds, X build, pre-installed-module packs
49. https://mybible.zone/pc/ — no PC app; emulator / scrcpy
50. https://mybible.zone/ios/releases/ + /ios/blog/ — iOS registry server fixes, 3.0.2 crash post-mortem
51. MyBible Modules Format (Scribd) — SQLite schema, zip convention, lookup algorithm
52. https://www.danielofthelions.com/mybible-guidebook.pdf — catalog walkthrough, sizes of the catalog
53. https://play.google.com/store/apps/details?id=ua.mybible — 4.7★/40.5K, "No data collected"
54. https://apprecs.com/android/ua.mybible — 4.8★/43K, rating distribution
55. https://justuseapp.com/en/app/1166291877/mybible/reviews — iOS 52% negative NLP
56. https://www.biblecenter.se/arkisto/raamattu/asennus-ohjelmat/Mybible_HELP_ENG_Android_IOS_ver_5.pdf — 2020 help PDF
57. http://www.biblesupport.com/topic/7803-mybible-for-android/page-4 — "lack of book modules"; dictionary-lookup praise
58. https://mybible.zone/android/guides/ — official guide index, user-contributed guides/videos

**Naming collisions (verified during research)**
59. https://mybible.com/ — unrelated social app
60. https://apps.apple.com/ua/app/mybible/id1166291877 — Serhii Maksymenko listing
61. https://apps.apple.com/si/app/mystudybible/id6743988874 — MyStudyBible, no bundled content
62. https://apps.apple.com/gb/app/mybible/id948744181 — mybible.ro, account + audio
63. https://theology.de/downloads/mybible---bibelprogramm.php — Free Bible Software Group, Zefania XML
64. Laridian MyBible 3.0 reviews (Palm) — the paid ancestor: https://the-gadgeteer.com/2003/06/12/mybible_3_0_palm_os_software_review/

---

## 5. Verification-status summary

| Claim | Status |
|---|---|
| STEP mobile app has **no** module download | ✅ github.com/STEPBible/stepmobile + AppBrain + App Store reviews |
| STEP Android app **removed from Play 10 Nov 2024** | 📄 AppBrain |
| STEP catalog = **706** entries on versions.jsp | ✅ counted by me today |
| STEP desktop catalog: two-pane, repositories, `+`, progress bar, R/N/G/V/I/S badges, filter box, USB install, removal | ✅ STEPBible_Modules.pdf |
| STEP bookmarks stored in **cookies**; no notes/highlighting/export | ✅ stepbibleguide/personal.html |
| STEP first-run "indexing stuck at 70%" is an unresolved known issue | ✅ STEP FAQ |
| STEP repos desynced since Oct 2021 | ✅ GitHub issue #35 |
| STEP data licence = CC BY 4.0 | ✅ stepbible.github.io — but ⚠️ paper says CC BY-NC-ND for newer sets |
| STEP "Personalising" help page is an empty stub | ✅ fetched, contains only "TODO" |
| STEP iOS dark mode added in 3.0.13 (Apr 2022) | 📄 soft112 changelog |
| MyBible modules are **SQLite3**, format publicly documented | ✅ Modules Format doc |
| MyBible catalog driven by a cached JSON registry (`persisted_registry.json`) | ✅ extra-registries page + 2024 incident post |
| MyBible has exactly **three** module states, and offline shows everything as "local only" | ✅ modules-manipulation tip |
| MyBible has **no** per-module size, batch total or free-space display | 🔶 strong negative: grepped docs + 7,800 lines of release notes, zero hits |
| MyBible delete lives on the Modules-window selection bar | ✅ (affordance itself 🔶) |
| MyBible catalog counts (3,000+ modules, 200+ EN translations, 84 dicts, 100+ commentaries, 78 plans) | ✅ guidebook, ~2021 — dated |
| MyBible language count "800+" (guide) vs "300+" (stores) | ⚠️ CONFLICT |
| MyBible never monetises, never accepts donations, collects no data | ✅ goals, no-donations, Play data safety |
| MyBible added "[More]" to every module dropdown in 5.7.0 to defeat "only KJV?!" | ✅ release notes |
| MyBible added third-party registries in 5.5.0 | ✅ |
| MyBible ships **no** audio, by policy | ✅ developer reply on Play |
| MyBible's sync path broke on Android 13; conflicts silently overwrite | ✅ synchronization page |
| Uninstalling MyBible deletes all user data (since 5.4.0) | ✅ blog warning |
| Aug 2024 registry regeneration bricked downloads; fix = USB + delete JSON | ✅ mybible.zone post |
| MyBible iOS 3.0.2 crashed on launch for all upgraders | ✅ mybible.zone iOS blog |
| MyBible 5.6.0 bricked startup; fixed in 5.6.1 | ✅ releases + blog |
| MyBible has no Books module type | 📄 biblesupport (2016, still quoted) |
| MyBible 2–8 Bible windows | ✅ how-to/difficult-fragment |
| MyBible has a true word-aligned interlinear | ❌ not found; 🔶 Strong's-inline only |
| "My Bible" / "Free Bible Software" / "vector-art editions" as described in the brief | ❌ **not verified — see §0** |