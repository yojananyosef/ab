# UI/UX & Feature Research: Logos Bible Software vs. Accordance

**Research date:3 October 2026.** All prices USD. I mark every claim as **[VERIFIED]** (read directly from a cited source) or **[INFERENCE]** (my reading of the evidence).

**Sources of record used**
- `logos.com` (subscriptions, perks, what's-new, get-started, bible-app, libraries) — JS-rendered pricing partially unreadable; used search snippets + third-party confirmations
- `support.logos.com` Zendesk API (authoritative first-party documentation) — ~20 articles read in full
- Apple App Store + iTunes Lookup API for `id=336400266` (Logos Bible) and `id=411970514` (Accordance)
- Google Play listing for `com.logos.androidlogos`
- `accordancebible.com` (home, shop, trial, crossover, iOS/Android pages, collections)
- `support.accordancebible.com` Zendesk API — ~30 articles
- Apple customer-review RSS feeds for both apps (3 pages each) — the richest source of honest criticism
- Third-party: nickstapleton.me, kevinpurcell.org, genewhitehead.com, credohouse.org, learnofchrist.com

**Could not access** (403/bot-blocked): `reddit.com/r/LogosBibleSoftware`, `community.logos.com` forum threads. I have **not** verified anything from those, and I say so below.

---

# 0. Quick pricing summary

| | **Logos** | **Accordance** |
|---|---|---|
| Business model | **Subscription for features + perpetual purchase of books** | **Perpetual only. No subscription.** |
| Entry price | Free tier forever; subscription $9.99/mo | $49 (or $49.90 — see conflict) for Basic Starter |
| Mid tier | Pro $14.99/mo · $149.99/yr | Collections ~$199–$999 |
| Top tier | Max $19.99/mo · $199.99/yr | Academic $998–$1,098; academic bundles quoted at $5,000+ by reviewers |
| Free trial | 30 days (60 via affiliates) | 90 days, fully functional, ~60 modules |
| Mobile cost | Free download; your account unlocks your books | Free download; modules are yours forever |
| Ads | **Yes on Android** ("Contains ads" on Play) | No |

---

# 1. LOGOS BIBLE SOFTWARE

## 1.A Reading Experience

### Layout: scroll by default, paged mode available
**[VERIFIED]** — `support.logos.com` article *"2. Navigate within Your Bible"*:
- Default is continuous scrolling with mouse or arrow keys.
- **"The Paged View option on the View tab enables you to switch between a simple scrolling view and a paged view where the text is laid out in multiple columns. In Paged View, using the Space bar will move the Bible to the next page."**
- Reference box shows current reference and accepts a new one to jump.
- `Contents` toggle on the Home tab opens a chapter-level table of contents.
- History arrows (back/forward) plus "article navigation icons" for next/previous article/book/chapter/verse.
- Spacebar paging + multi-column paged layout is a genuinely nice touch no mainstream Bible reader ships.

### Verses, numbering, current-verse tracking
**[VERIFIED]** — *"2. Navigate within Your Bible"* + *"Enhance Your Reading Experience with the Notes and Formatting Tabs"*:
- **Current-verse tracking is done by the reference box**, which "displays your current reference" as you scroll. There is no separate persistent "current verse" indicator concept — the reference box *is* the indicator.
- Verse numbers are toggleable: the Formatting tab → Reformatting offers "enabling showing each verse on a separate line" and "controlling how much additional information is given" (verse numbers, footnotes, section titles all suppressible). Mobile View Settings → Reformat text likewise lets you "show or hide… chapter/verse numbers, footnotes, and more."
- **[INFERENCE]** Verse numbers are rendered inline superscript, not in a gutter column. I could not find a first-party doc stating this.

### Typography controls — the richest set I found in either app
**[VERIFIED]** — mobile View Settings (`support.logos.com`360035445412) enumerates:
- **Font Size** (slider), **Line Height** (slider), **Line Width** (slider = side margins), **Brightness**
- **Appearance: system / white / sepia / black (dark)** ← exactly the four-theme model requested
- **Fonts chosen separately for English, Greek, and Hebrew**
- **Red Letter Text** (words of Christ in red)
- **Justify Book Text**
- **Scrolling View** toggle (continuous document vs paged)
- **Swipe to Highlight** (off by default-offable)
- **Smart Text Selection** (expands selection to nearby boundaries e.g. a whole verse)
- **Keep Display On**
- Desktop: Program Settings → Text Display → **"Default Book Font"** dropdown ("there are many"), plus per-book Font Size + content scaling on the View tab.

### Multiple translations side by side — four different mechanisms
**[VERIFIED]** — `support.logos.com` *"3. How to Read Your Bible and other Resources Together"* and *"Three Tools to Compare Bible Translations"*:

1. **Add parallel text** (View tab) → check-box list of resources; can be laid out **vertically or horizontally**; all panes scroll in lockstep. **Asymmetric by design:** "the secondary resources follow when you scroll in the primary (or 'host') book. However, the converse is not true."
2. **Multiple Resources View** — same feature, saved views; "As you scroll in any one Bible, the others will stay in sync."
3. **Text Comparison Tool** — genuine word-level diff: differences in blue, base text on hover, or inline with strikethrough.
4. **Passage Analysis** — three visualizations:
   - **Compare Pericopes** — how different translations split a passage
   - **Cluster Graph** — a 2D scatter where "the closer together translations appear… the greater the degree of similarity" (ESV clusters near NRSV, far from NASB95)
   - **Version River** — verse-by-verse difference bars with % differences, color-coded, zoomable

Plus **Insights Panel**: a sidebar inside the Bible panel showing a snippet from your Study Bible and Commentary at the current passage, expandable via "More," with a `Change` dropdown to swap which commentary, and click-through to open the full section. **[INFERENCE]** This is the single best idea in either app for a mobile reader: a persistent, context-aware commentary sliver that never navigates away.

### Phone vs desktop with the same license
**[VERIFIED]** — one account, one license. `Logos Platform Comparison` article is a 90-row feature matrix (Desktop / Mobile / Web) with 12 footnotes on partial functionality. Highlights:
- Mobile apps are **free to download**; a Logos customer's library appears in them. All base-package books are supported on mobile; anything marked "Runs on internet" is available on mobile.
- **Requires iOS 18.6+** (App Store listing) — aggressive.
- Mobile **streams** your library from the cloud rather than storing it; you must pre-download for offline. **Full-library search, Passage Guide, and Bible Word Study require an internet connection even when the text is downloaded** (`Which Logos features require an online connection?`).
- Feature fragmentation (documented by Logos itself):
  - Highlights **and their Labels**: desktop only
  - **Corresponding Notes** (showing a note made in another book): desktop only
  - Prioritization of books: set on desktop, used elsewhere
  - Collections: usable on mobile, **not creatable**
  - Reading Plans: all types creatable on desktop; a few on tablets; **not creatable** on web or phone
  - Atlas on mobile "is clickable in the mobile app menu but opens the web app"
  - Advanced Timeline, Canvas, Draw on Screen: iPad only
  - Print/Export: **desktop only**
  - Sermon Builder/Manager/Assistant: iPad + Android tablets only, and on Android requires Pro+ subscription
- Their own advice: "if you plan to be offline for an extended period… or if you need the most powerful study tools, Logos Bible Software on a laptop would be a better option."

---

## 1.B Navigation

### Reference entry
**[VERIFIED]** — accepts many formats: `John 3:16`, `jn 1 1`, `1 John 1:1–3`, `1jo 1 1–3`, `1st John 1.1–3`. Entering book+chapter alone opens verse 1. `set preferred Bible` promotes a version to your Top Bible.

### Reference Scanner (camera)
**[VERIFIED]** — mobile only, "Available in Logos Plus and higher". Scans one or many references from camera or photo library; sort by reference or scan order; verse-preview toggle; save as a Passage List. **This is a feature neither Accordance nor most competitors have, and it is genuinely great.**

### Search — scope, modes, syntax
**[VERIFIED]** — `How Do I Search in Logos?`

**Search types:** All, Bible, Books, Factbook, Docs (your own documents), Media, Morph, Maps, Factbook Tags, Bookstore, **Clause**, **Syntax**.

**Two modes, switchable:**
- **Smart Search** (AI, all tiers, credit-metered): natural-language queries
- **Precise Search**: deterministic, syntax-driven

**Operators:**
| | |
|---|---|
| Phrase | `"kingdom of God"` |
| Wildcards | `*` (0+ chars), `?` (exactly 1) |
| Boolean | `AND` `OR` `NOT` — **must be capitalized** |
| Proximity | `NEAR`, `WITHIN 5 WORDS`, `WITHIN 5 CHARS`, `BEFORE`/`AFTER` |
| Grouping | `( )` |
| Fields | `speaker:Jesus`, `topic:Sabbath`, `author:augustine` |
| Ranges | `John 3:16-17`, `Matthew 5`, Pauline Epistles |
| Morph | `@` tag: `love@NN`, `g:agape@N-NSF` |

**No regex** in the classic sense — wildcards are `*`/`?` only. **[VERIFIED by absence of documentation]**; **[INFERENCE]** a power user will feel this.

**Clause Search** (higher tiers): "terms acting in specific grammatical or semantic roles within sentences or clauses."

### Labels — a structured metadata system worth stealing
**[VERIFIED]** — `Using Labels`. A Label = **Class Name + Attributes**, where an Attribute has one or more values. Biblical examples: `Command` → Type (Advice / Offer / Permission); `Miracle` → Instrument / Patient. Non-biblical example syntax:
```
sermon:series:"The King and the Kingdom"
sermon:references:"Eph 1:15-23" AND sermon:creator:Piper
sermon:date:"Jul 1989"
sermon:* NOT sermon:series:*
```
Also used to *narrow* a plain word search (find non-metaphorical uses of "sheep"). Labels appear as blue underlines in Bible text. Important caveat documented by Logos: **"Labels are specific to resources… most extensive in Bibles and limited in other resources."**

### Passage Lists
**[VERIFIED]** — Create from: search results (auto-named after the search) · references inside any other book (auto-detected) · scratch. Then: add section headings, sort to canonical order (also de-duplicates), drag to reorder, add from clipboard, add entire other lists, **use the list as a filter over the whole Bible text**, memorize it, share it, export to calendar.

### Notebooks / notes / highlights organization
**[VERIFIED]** — `Organize Your Notes with Notebooks`:
- Notebooks organize notes + highlights across resources
- **A note can only be in one Notebook at a time** — "If a note fits in multiple locations… create additional tags for the note" (so: notebooks = folders, tags = the multi-membership mechanism)
- Deleting a notebook deletes its notes — **but there is a Trash with Undelete** at the bottom of the Notebooks tab
- Notebooks can be shared **publicly or to a specific Faithlife group**; "Copy to" produces a shareable link

### Reading plans
**[VERIFIED]** — `Work Through Your Books with Reading Plans`: a wizard. Sources = whole Bible / specific passages / a book in your library / custom / a Faithlife-group plan / predefined. Pace = scheduled (pick start date, days of week, optional mobile reminder + notification time) **or** unscheduled. Goals = finish by date / minutes per day / number of sessions. Progress renders as a **blue ribbon** in the text with start/stop markers, plus a Dashboard card. Syncs across desktop/web/mobile. Custom Reading Plans = Pro & up. Mobile v53 added a **Reading Plans Manager** (track, discover, organize, edit dates/days/goals).

### Other navigation furniture
Layouts (saved workspaces) · Favorites · Collections · Prioritized Resources (Top Bible / Top Study Bible / Top Commentary) · a shortcuts bar you can drag books onto · Library filters by subject/type/author/publisher (`type:commentary`, `type:"study bible"`, `type:lexicon`).

---

## 1.C Study Tools

### Guides
**[VERIFIED]** — Passage Guide · Exegetical Guide · Factbook · Topic Guide · Sermon Starter Guide. Guides "conduct complex, pre-defined searches across your library and organize the results into a comprehensive report based on a specific passage, topic, or word" — cross-references, biblical people/places/events, sermons, media. Each Guide section is itself a search you can run.

### Factbook
**[VERIFIED]** — `What can I do with the Factbook?`: articles on people, places, events, topics, **book**, original-language lexemes, and counseling themes. A Factbook article shows the passage text, linked sub-articles, **Biblical Events** (which period of Jesus' ministry), **Reported Speech** (who spoke to whom), Commentaries from your own library, and a **Dig Deeper** section. **Factbook Tags** are blue underlines in the text that jump to the Factbook entry; other users' Factbook tags are visible online and are community-editable. Subscribers can one-click summarize entries (AI credits).

### Cross-references / parallel / typological
**[VERIFIED]**
- Cross-reference markers and data surface through the **Passage Guide** and the Bible's own footnote/cross-reference layer (many translations carry them; `Why do ordering and verse numbers differ between Bibles?` exists as a support doc)
- **NT Use of the OT Interactive** (Premium & up) — "See how biblical authors allude to, cite, echo, or quote the Old Testament in the New Testament. **You can even search for specific words or phrases within your results.**" This is the typological/Qumran layer, and searchability inside it is the interesting part.
- **[INFERENCE]** Logos does not ship a first-class *harmony* widget the way Accordance ships separate Harmony/Synopsis/Synoptic parallel modules. It relies on Passage Guide + NT-use-of-OT. I found no harmony module.

### Lexicons, morphology, interlinears
**[VERIFIED]**
- **Morph Query document** (Max + legacy Silver+) — a **spreadsheet-like grid**: one column per search term, one row per property (Lemma, Part of Speech, Case, Number, Gender…). You pick the resource first, which determines which properties appear. Supports OR groups, `Exists` negation ("search for where no article is present"), and a **Search Span** row for proximity ("how many other words can be in between"). The worked example is a genuinely excellent tutorial: using an interlinear to find that `ἐν τοῖς ἀποστόλοις` = prep + plural dative article + agreeing noun, then building a morph query to ask whether Romans 16:7's "well known to/by the apostles" is correct. **This is the best single piece of study-tool design I found in either app.**
- **Syntax Search** (Greek/Hebrew databases; ETCBC Hebrew/Greek mentioned) — searches grammatical relationships, with a graphical **Query Builder**.
- **Bible Word Study Guide**, **Power Lookup**, **Information Tool** (definition, popular English translations, original-language info on hover), **Reader's Edition Interlinear**, **Reverse Interlinears**, **Bible Sense Lexicon**.
- **Reference Scanner**, **Concordance Tool** (online-only).

### Footnotes & commentary integration
**[VERIFIED]** — three distinct patterns:
1. **Inline / reformat** — footnotes are toggled on/off in Reformat text; `[INFERENCE]` they render as hyperlinked superscript numerals in the pane.
2. **Insights Panel** — Commentary snippets *inside* the Bible panel with "More" expansion. (`[VERIFIED]` as a feature; `[INFERENCE]` that commentary text renders inline rather than in a docked pane.)
3. **Link sets** — a commentary in its own pane scrolls in lockstep with the Bible. **Documented limitation: link sets only work between resources with overlapping milestone types.** "You couldn't link a Bible to a monograph, because monographs typically have page numbers as milestones rather than verse numbers." A linked lexicon behaves differently again — it jumps to the entry for whatever word you *click*.

### Maps, timelines, charts, media
**[VERIFIED]** — **Atlas** (online-only) with map markers embedded in the text; **Advanced Timeline** (iPad) with timeline events in the text; **Media Tool** (images/video/audio, online-only) with Verse of the Day markers; **Charts** tool; **Sentence Diagrammer**; **Word Lists**; **Word Find Puzzle**; **Auto-translate** (Max); **Print Library Catalog** and barcode-scan your print books so their results appear alongside digital ones.

### AI surface
**[VERIFIED]** — `What's included in Logos subscriptions?`:
- **All tiers:** Smart Search · Search Results Summaries · Study Assistant (chat over your library *and the wider catalog*, with follow-ups) · Summarization Sidebar · Insights Sidebar
- **Pro & Max:** Sermon Assistant — four generators: Outline, Illustrations, Discussion Questions, Applications. Desktop, web, iPad, Android tablets.
- **Mechanics worth copying:** all AI requests consume **credits**, "renewed each month," with a **remaining-credit indicator in the toolbar**. This is the correct UX for metered AI.
- **[INFERENCE]** The App Store description says Study Assistant/Smart Search have "limited free uses" on the free tier, so credits exist below subscription too.

---

## 1.D Synchronization and Data

**[VERIFIED]**
- Apps are free on desktop (Windows/Intel Mac/Apple Silicon), web, iOS, Android, **and Amazon App Store for Kindle Fire**. Free account unlocks the app; a free tier exists permanently ("Free Edition" is a first-class state in the About panel alongside Legacy / Premium / Pro / Max).
- **Books are never rented.** Books and libraries you buy are perpetual; only *features* are subscription-gated. Legacy pre-2025 base packages (Libronix/Logos 3 → Logos 10) are honored as "Legacy Edition" with ownership-discounted subscription rates.
- **Legacy Fallback License:** after **24 consecutive months** of subscribing, you keep your tier's offline (non-cloud, non-AI) features forever if you cancel. Requires that you previously owned a base package.
- Free books: 40+ Bibles and works per the App Store listing.
- **Mobile is streaming-first.** Resources are not stored by default; pre-download for offline. AI, All Search, Media Search, Factbook Tags, Atlas, Bible Browser, Text Comparison, Reading Lists, Store, and Sync all require a connection; several degrade rather than fail.
- Sync covers notes, highlights, reading plans, prayer lists, documents. Mobile View Settings sync to other mobile devices.
- **Export/print (desktop only):** Print/Export dialog (Cmd/Ctrl+P) with margins (Normal/Narrow/Moderate/Wide), Auto/Single columns, "Print as shown on screen" vs "Print as exported", "Visible results only", "Fit to page"; export to RTF, TXT, HTML, XPS/PDF, PNG/BMP/JPEG/TIFF/GIF, Excel, **.ics calendar for reading plans**, and citation files; "Send to new document" into Word/Excel/PowerPoint/Keynote; "Paste into open document". Plus Copy Bible Verses (custom styles), Export Library to spreadsheet, Clippings export, Bibliographies.
- **Hard limit:** "For various licensing and technical reasons, we can not export Logos resources to other formats" — so no Kindle/e-reader export.

---

## 1.E What is good, what is bad

### Genuinely excellent (copy these)
1. **Insights Panel.** A study-commentary sliver that lives *inside* the Bible pane and updates with your scroll. Zero navigation cost. This is the pattern I'd build a mobile reader around first.
2. **Text Comparison + Passage Analysis.** Real linguistic diffing (differing words in blue, hover for base text, inline strikethrough mode) plus three distinct visualizations. A casual reader would never build these; a translator uses them daily.
3. **Link Sets with honest constraints.** Named A–F link sets, and the docs explain *why* certain pairs can't link. Good design includes the failure model.
4. **Morph Query as a grid, not a query language.** Spreadsheet-shaped morphology builder with visual OR-grouping and `Exists` negation.
5. **Reference Scanner.** Camera → multiple references → sorted list → saved Passage List.
6. **Reading plan ribbons in the text.** Blue ribbon with the day's passage, start/stop markers, dashboard card, calendar export, mobile reminders.
7. **Labels with Class + Attribute structure.** Turns "find commands of type Advice" into a first-class search. Also repurposed for sermon metadata — same engine, two domains.
8. **AI credits with a visible meter.** Metered AI with a persistent remaining-credits readout is the honest way to ship AI.
9. **Free tier that actually works** and a documented commitment that it stays ("Will the free version of Logos continue to be available?").
10. **Trash/undelete for notebooks** — a small, correct safety net.

### Dated, confusing, or broken (avoid these)
1. **The Android build is ad-supported.** Google Play lists "Contains ads". A paying customer with a $400+ library writes: *"As much money as I've spent on this software, I am riddled with ads and they just made it so that you can't turn them off. My dashboard is unusable now because there are so many ads."* **[VERIFIED, App Store/Play review]** Monetizing a paid product with unskippable ads on one platform is a serious trust violation.
2. **Feature fragmentation is self-documented.** Logos publishes a matrix showing mobile is missing corresponding notes, highlight labels, reading-plan creation, and printing. Users feel it as "the phone version isn't the real thing."
3. **Serial UI upheaval without versioning.** The single most common1–3★ complaint. Verbatim, from the iOS review feed:
   - *"Logos mobile update to v 53 is a step in the wrong direction… in previous versions when you were in a book on the bottom bar you had direct access to your Library now it is direct access to the store."*
   - *"New UI — The new UI is complete garbage. It seems like every new UI overhaul is worse than the previous."*
   - *"It is not easy anymore to go back to the screens you were previously on."*
   - *"Hate is not a strong enough word for this update… I accidentally clicked on an AI search tool and now I cannot even find my library on my iPad."*
   - *"The desktop reader is a marketplace before it's a library these days, and now they literally removed the Bible tab on mobile."*
   - *"The app keeps changing basic features so that I am constantly relearning how to navigate and search methods and terms."*
4. **AI displacing deterministic search.** *"The AI addition interferes with word searches and, for the mobile edition, eliminated the tabs which made book selection simple."* and *"an A.I. icon popped up, letting me know that the search engine has been replaced by a pay to play type feature… now I have to pay for an upgraded search feature that doesn't work as well as the standard version."* Smart Search should be an *additional* mode reachable in one tap, never the new default that hides Precise Search.
5. **Stability.** *"A year later and this app is still unstable, losing downloaded books, reading plan unsynced. The most important feature in a program is it's stability, unfortunately Logos still does not it have it."* Plus crashes, a delete-key bug that removes five letters at once, and *"iPad app is still buggy… the highlighting feature ceases after a while."*
6. **Onboarding cliff.** *"Very Hard to Use — Everything is complicated. Must spend more time figuring the app out than using it. Patchwork construction, not at all intuitive."* and *"Logos Bible Software is like the greatest library in the world that won't let you in… I am not a tech guy."*
7. **Pricing matrix explosion.** Tracks × tiers × denominations × years. **[VERIFIED]** the matrices exist: 8 library levels (Starter/Bronze/Silver/Gold/Platinum/Diamond/Portfolio/Collector's) × tracks (Standard/Learner/Leader/Preacher/Researcher) × denominations (Anglican, Baptist, Catholic-Verbum, Charismatic, Lutheran, Messianic Jewish, Orthodox, Reformed, SDA, Wesleyan, Ultimate) × edition year (2026…). Kevin Purcell, an affiliate, still writes: *"Their offerings look too complicated. I wish they'd simplify things, but people love the dizzying array of options."* Third-party price anchors: 2026 Starter $39 (value $404.17), Bronze $89 ($939.80), Silver $349 ($3,853.26); 2025 Portfolio $3,324.99; Collector's $7,699.99.
8. **Typography settings don't reach everywhere.** Documented: "font size adjustments do not affect the font size of the library menu, notes, and prayer lists."
9. **Print/export desktop-only.**
10. **Stale naming.** The iOS App Store description still says *"subscription plans called Logos Plus and Premium"*, and the Reference Scanner doc says "Available in Logos Plus and higher" — but the actual tiers are **Premium / Pro / Max** (confirmed by the About panel). Leftover copy from a discontinued tier scheme, still shipping.
11. **Aggressive OS floor** — iOS 18.6+ required.

---

# 2. ACCORDANCE

## 2.A Reading Experience

### Layout: pane/zone workspace, not a page
**[VERIFIED]** — `Accordance Equivalent Features for Logos Users Also Using Accordance`:
- Accordance's core metaphor is **tabs grouped into zones inside a workspace**; any zone can be **magnified to take up the entire workspace**. "Layouts" in Logos = "Workspaces" in Accordance. Saved Workspaces are the unit of organization.
- Each module opens in a **tab**; navigation buttons sit at the bottom of every text window; a **Go To** box at the bottom of a text window accepts a reference directly.
- **Bible-central launch**: "Accordance opens to your preferred Bible translation, making the text the focus of your study."
- **Reading Mode and Slide Show Mode** for distraction-free reading and presentation.
- **Info Pane** = Logos Passage Guide/Explorer equivalent, docked beside the text.

### Verses, numbering, current-verse tracking
**[VERIFIED]**
- Verse numbers are per-module, and versification genuinely differs between texts. Support article *"There are verses missing from my text pane"* documents the interesting case: in a few Psalms the Hebrew heading occupies two verses, so "vs 1 in Hebrew matches vs 0 in English."
- **Their fix is a design decision worth stealing:** "the Accordance 11.2 will display these apparently missing verses in parallel panes," and the user workaround is "make the text in which text seems to be missing, the search text." So: **Accordance surfaces versification mismatch by re-scoping the parallel view rather than silently blanking a verse number.** No other app does this.
- Mobile has a dedicated **Verse Chooser** and a **Quick-Click Verse Picker** (added in v14, "borrowed from our mobile versions") that works for any chapter-and-verse text — Josephus, Philo, Dead Sea Scrolls.
- **[VERIFIED]** App Store description: "tap on hyperlinked verse references to view the full passage in the Instant Details popover."

### Typography / appearance
**[VERIFIED]**
- **Settings > Appearance**: Light Theme / Dark Theme / **"Match System Dark Mode."** v14.1 specifically fixed a bug where the popup "would attempt to track the current system mode and had issues when toggling the Match System Dark Mode checkbox." So: system/light/dark toggle exists; **no sepia option found** — Logos is ahead here.
- Font size via the **double-A icon** on any text or tool window; **Show Interlinear** menu sits next to it.
- **Morphological color coding** — colors parse codes directly in the Greek/Hebrew text (documented in their eAcademy course).
- **Read Aloud / Speech** — Mac only at the time of writing.
- Android changelog (v2.1.0) added **Automatic Day/Night Theming**.
- Mobile "Advanced Reading Settings" exist (article is video-only, so specifics unverified).

### Multiple translations side by side
**[VERIFIED]**
- **Add Parallel button (+)**: adds as many panes as you like, horizontal or vertical; all scroll in sync. **You can unlink individual panes** (`QuickTip: Unlinking Parallel Panes in Accordance Mobile`). Unlinking is the escape hatch that makes multi-pane usable for non-parallel passages.
- **Compare checkbox** on text windows: displays one text interlinearly against another.
- **Text Browser** (`File > New Tab > Text Browser`): *"You can view all of your Bible versions for a passage."* Every installed version at once — the cleanest "which translation says what" surface in either app.
- **Text Comparison** tool.
- **Research tab** = "searching multiple books in your library" (Logos Multi-Search).
- App Store description: *"Compare two Bible translations side by side that will scroll in sync with one another."*

### Phone vs desktop with the same license
**[VERIFIED]**
- **Mobile apps are completely free** — "Best of all, its completely free" — with the same account unlocking your purchased modules. **No separate purchase or subscription for mobile.**
- **Desktop license is separate and required for desktop only.** The trial page is explicit: "The program or search engine is necessary in order to download and use the Accordance resources on a computer (Mac and/Windows)."
- Mobile parity is materially lower. Documented exclusions: the Parallels modules are all labeled **"(not for Mobile)"** — Gospel Synopsis, Gospel Harmony, Synoptics, OT Parallel, OT-in-NT, Epistles, Q (Sayings). Genealogy tools also "(not for Mobile)."
- Reviews are blunt about the gap: *"Has little to no parity with the desktop app. The most important feature I would want on mobile is searching and looking up original language references, and it simply cannot manage. I can see a word in the GNT, type it exactly in the search box, and Accordance will fail to find it anywhere (including the passage where I first saw it)."*
- Desktop needs no internet except for account validation and module downloads (**[VERIFIED]** support statement) — a real advantage over Logos mobile.

### The highlight system — the best single feature in either app
**[VERIFIED]** from `Highlighting Your Bible: Top 5 Advantages of Accordance Over Print`:
1. **User-defined styles** — combine color, intensity, shape, and **pattern** (e.g. "dotted underline with a bright red border"). Defined under `Highlights > Define Highlight Styles`.
2. **Multiple highlight files** — separate style sets you switch between with one click ("theological themes" / "personal devotion" / "teaching prep"). You can highlight the same verse several different ways without clutter.
3. **Highlights are reference-scoped, not version-scoped** — "When you highlight a verse by selecting its reference, that highlight isn't tied to just one translation, it shows up in all of them." Switching from ESV to NIV to NASB and your markup is already there.
4. **Highlights are searchable** — the `[STYLE]` command in a word search returns every verse marked with a given style. Effectively a personal thematic index generated by marking up your Bible.
5. **Fully reversible** — erase and redo freely.

**This is the design I would copy first for any Bible reader.** Patterns + intensity + swappable files + cross-translation persistence + searchability is a complete annotation system that neither free apps nor YouVersion-class readers come close to, and it costs nothing to implement.

---

## 2.B Navigation

### Table of contents / book-chapter navigation
**[VERIFIED]**
- Library pane permanently docked left, divided into **Texts** (Bibles, Apocrypha, Church Fathers, Talmud, Josephus, DSS, Philo, Pseudepigrapha, Qur'an) · **Tools** (most secondary sources) · **Databases** (Syntax Graphs, Greek Diagrams, Targums WordMap) · **Parallels** · **Background** (Atlas, Timeline) · **Visual Tools** (Logos Media) · **Accessory Modules** · **My Stuff** (Logos Documents).
- **Book switcher menu sits immediately to the left of the search box** in every text and tool (Logos "Parallel Book Sets" equivalent) — very fast for jumping between parallel modules.
- **Quick-Click Verse Picker** (looks like a TOC icon) in every text window; works for any chapter/verse text.
- **Context slider** to the right of the verse picker adds surrounding verses to any search.
- Bottom-of-window nav buttons + Go To box.
- Library management depth is real: dividers, alphabetizing, a filter, search-library-by-Scripture, **PDF of your library contents**, **RIS export** of library contents.

### Search**[VERIFIED]**
- **Keyboard-first command syntax with an autocomplete "Quick Entry" drop-down listing every valid command as you type.** This is the crucial difference from Logos: you don't need to memorize syntax, the app tells you what exists.
- `[FUZZY]` searches for approximate matches.
- **Range and Scope buttons** (`+`): Range = OT / NT / etc.; **Scope = Chapter, Verse, Clause, Sentence, Paragraph, or Book.**
- **[STYLE]** searches highlight styles (see above).
- **Construct searches**: a graphical query builder in three flavors — Simple (primarily English), Greek, Hebrew — explicitly the equivalent of Logos Morph Query.
- **Tag syntax** (`@`) for morphology; **Lemma** and **inflected form** search.
- **Analytical search results** — "using robust analytics tools, you can analyze your search results to discover patterns and trends." Words in search results show **Frequency, Uniqueness, and Importance** with the type of analysis named in the heading and appropriate decimal places (v14.1 fix).
- **Word Charts**, **Parsing** outputs from any biblical text.
- **Advanced features with dedicated documentation:** Basic/Advanced Greek searches · Basic/Hebrew searches · Greek/Hebrew **Construct** searches · Power Searches · `[FUZZY]` · Searching on **cantillation patterns**.
- **Hypertext references:** in Tools/User Notes, drag a selection *across* multiple hyperlinked references to open them all at once — but you must start and end the drag *inside* the first and last reference, otherwise it degrades to text selection. Clever, and documented with a screenshot-worthy explanation.
- No regex-style wildcards documented; `*` and bracket grouping exist. No camera-based reference scanner.

### Bookmarks, favorites, notes, reading plans
**[VERIFIED]**
- Terminology map: **Bookmarks** = Logos Favorites · **User Notes** = Logos Notes · **Stacks** = Logos Clippings · **Papers** = Logos Sermon Builder · **My Groups** = Logos Collections · **My Places** (a saved navigation position, added in Android v2.1).
- Highlights organized in files (see above).
- **Daily reading:** a **Devotional workspace** (equivalent to Logos QuickStart) plus `Chronological Readings` and `Devotional Readings` modules in the free set.
- **[VERIFIED]** Accordance has *daily* reading workflows (`Accordance Basics: Daily Reading`, `QuickTip: Daily Bible Reading Plans`) but **no custom reading-plan builder equivalent to Logos' wizard** — plans come from shipped modules and devotionals. This is a real gap for a modern app.

---

## 2.C Study Tools

### Cross-references and parallels — deeper than Logos
**[VERIFIED]**
- A dedicated **Cross-References module** is "included in any level of the Library 6" — i.e. it's not a premium add-on, and every reference in it is individually hyperlinked.
- **Seven parallel modules**, all desktop-only: Gospel Synopsis · Gospel Harmony · Synoptics · Old Testament Parallel · Old Testament in New Testament · Epistles · Q (Sayings). Explicitly catalogued as parallels, not generated on the fly.
- **[VERIFIED]** Typological/intertextual: `Lighting the Lamp: Exploring Intertextuality Between Texts`; also Accordance General Searchable Equivalent of Logos's NT-Use-of-OT.
- *[INFERENCE]* There is no Accordance equivalent of Logos's **Cluster Graph / Version River** translation-difference visualizations. I found no such tool in the support catalog.

### Lexicons, dictionaries, morphology
**[VERIFIED]**
- **Dictionary lookup is bound to a click, not to scroll.** When a Bible is linked to a lexicon, "instead of scrolling as you scroll down your Bible, your lexicon will open to the entry for whatever word you click." More precise than Logos's milestone-based linking.
- **Triple-click → quick definition. Double-click → Amplify** (choose which tool to look the word up in). **Live Click** searches many tools from any text with one click. This is a genuinely excellent three-tier progressive-disclosure model.
- **Instant Details**: press-and-hold in mobile → magnifying glass → select a word → definition and/or parsing. Tap again to look up in a dictionary.
- **Dynamic Word Study Pane** (v14): "From any morphologically-tagged original language Text or translation with Key numbers, you can launch the Dynamic Word Study Pane. From there, you can get extensive information on your word, **compare texts, create charts, and pull up information from lexicons, grammars, and even journals!**"
- **Characters window** for typing Greek/Hebrew directly.
- Available lexica: Strong's Greek/Hebrew, BDAG, HALOT, DCH, LSJ, Jastrow, BDB, KM, Mounce, Thayer, Jenni-Westermann, Louw-Nida, and more.
- **Morphological tag editor/filter dropdowns** (v14.1 added HMT-W4 adjective "unspecified," and the Adjective tag pull-down now shows the right tags per text and **dims inapplicable items** — e.g. in the Qur'an module).

### Footnotes / commentary integration
**[VERIFIED]**
- Commentaries are **parallel panes**, not inline. `Accordance Basics: The Add Parallel Button` and the Apple description: "makes it easy to view a commentary or study notes in parallel with your Bible."
- Study Bible footnotes and cross-references are inside the text module itself; the free iOS set includes "Margin notes and cross-references" as a standalone item.
- **Hypertext everywhere**: verse references inside Tools, User Tools, and User Notes are clickable, and multi-select drag opens many at once.
- **[INFERENCE]** Because commentary lives in adjacent panes rather than inline, Accordance is *better* for comparing commentary to text but *worse* than the Logos Insights Panel for a quick glance on a phone. This is the clearest single UX trade-off between the two products.

### Maps, timelines, images
**[VERIFIED]** — "interactive 3D maps" and 3D-modeled tools (Logos-equivalent page). **Atlas** and **Timeline** live under `Background` in the Library. Timeline events hyperlinked from module text boxes; Timeline has an **Expanded Edition**. **PhotoGuide** photo collections (Atlas Sampler and Timeline Sampler are in the free set). Free set also includes a **Maps Sampler** and **Timeline Sampler**.
- Criticism **[VERIFIED, review]**: *"I love accordance. The maps need enhancing and the ability to search resources on my iPad. Sermon prep is difficult without a desktop or laptop."*

### Prose/authoring features that are quietly excellent
**[VERIFIED]** — Accordance 14 shipped things no competitor has:
- **Custom Phrasing** — "create line breaks and indents directly in a biblical text… demonstrate a chiasm… repositioning texts for discourse analysis… isolate some phrases." **You can lay out your own chiasm inside the actual text.** Nothing else does this.
- **Easy Answers** — "editable fields in which to record your answers right in the study guide or workbook." Built-in worksheet completion.
- **User Dictionaries and User Commentaries** — build your own reference works, alongside User Tools and User Bibles.
- **Unicode in User Tools** — full CJK/Thai support.
- **Citation formats:** Turabian, SBL, Simple, **plus APA, Chicago Manual of Style, and MLA**. Citation Markers with configurable strings (v14.1 fixed a bug where blank marker strings reset to default and corrupted copied citations).
- **Sentence Diagramming**, **Custom Phrasing**, **Analytics**.

### Alternative texts and versifications
**[VERIFIED]** — a very long tail, which is a genuine differentiator: Coptic NTs · NT Peshitta · OT Peshitta · Samaritan Targum / Samaritan Pentateuch · Targum English · Targums Tagged Aramaic · Latin Nova Vulgata, Clementine, Vetus Latina, Weber tagged (+ Latin Vulgate Apparatus) · Qumran Aramaic Dictionary · Inscriptions Index · Hebrew Mishna (Kaufmann) · Qur'an · Josephus, Philo, Apostolic Fathers, Pseudepigrapha, Dead Sea Scrolls · Ancient Christian Texts · Septuagint (multiple) · Apocrypha.

---

## 2.D Synchronization and Data

### The "module" concept
**[VERIFIED]** — Accordance's add-on unit is called a **module**, and the parallel unit for user-created content is **User Tools / User Bibles / User Dictionaries / User Commentaries**.
- Modules are bought on the website and downloaded via **Easy Install** (Accordance menu on Mac, Utilities on Windows) or in-app on mobile. App Store listing confirms **In-App Purchases: Yes**.
- Free module content out of the box: **ESVi (ESV + Strong's), WEB, samples of the Greek NT and Hebrew Bible, Easton's, outlines, margin notes & cross-references, PhotoGuide Sampler, KM and Mounce dictionaries, BiblicalTraining.org.** Registering an account adds a further free starter set (ASV, Louis Segond, Elberfelder 1905, Lutherbibel 1912, Greek & Hebrew Strong's, Hitchcock's, Nave's, Almeida, RVR09 + Strong's, Dr. J's BSM, Maps/Timeline Samplers, Chronological Readings, Devotional Readings, Classic Passages, Parables & Miracles).
- **[VERIFIED]** "Internet access is only required to validate your account and download and update the titles in your personal Accordance Library. Internet access is not required for normal use."
- **Library categories are semantic, not alphabetical** — Texts / Tools / Databases / Parallels / Background / Visual. Much better information architecture than a flat alphabetical module list.

### Sync — currently the weakest part of the product
**[VERIFIED] from release notes and support articles**
- Historically: `Sync with Mobile Device` (Wi-Fi) + `Sync with Dropbox`.
- **v14.1 (released Sept 2025) REMOVED Dropbox syncing.** Support article: "Dropbox syncing was removed in version 14.1."
- Replacement, **Accordance Sync**, shipped as an **"open beta"** inside **Accordance Aleph** (their beta channel), and as of the 2026-08-15 docs: **manual sync only, User Note conflicts auto-resolved, Preferences sync optional.**
- Mature touches: `Settings > Syncing` shows **file sizes per syncable file type and the running total**; uninstalled User Notes/Tools are excluded from size math and from sync; a **log file** records local and remote totals plus large files; "Remove Item" now *archives* User Notes/Tools instead of destroying them; the error message tells you whether the limit was hit locally or remotely.
- **Hard size cap: iOS 3.5.1 (Dec 2025) raised the syncable total to 100 MB** — up from 50 MB. One reviewer: *"Ditches Dropbox for 'Accordance sync' with 50 MB limit on total data size. My notes are much larger."*
- Syncable items: User Notes, User Tools, Highlights files, My Places, Preferences, Papers, citation marker settings.
- Mobile beta is via **TestFlight with a form and limited spaces**; beta installs **replace** the public app; a dedicated test device is recommended.

### Export/import
**[VERIFIED]** — **Save Text Selection** (Logos "Export") · **Copy As > Citation / Bibliography** · **RIS export** of library contents · **PDF of library contents** · exportable diagrams. Import: **BibleWorks notes** (there's a dedicated "Import BibleWorks Notes" workflow). Also: **30-day refund policy**, once per lifetime per account, requires answering seven questions by email; **no refunds on in-app purchases** (must go through Apple/Google/Amazon).

### Pricing detail (verified)
| Item | Price |
|---|---|
| Basic Starter (Accordance 14) — the 90-day trial's paid form | **$49** on homepage/trial page; **$49.90** in the shop — *conflict* |
| Accordance Software Version 14 Upgrade | $38.00 |
| Starter Collection 14 — English / Greek / Hebrew Specialty | $99.90 each |
| English Learner / Greek & Hebrew Learner | $199.00 |
| Triple Starter (Eng + Gk + Heb) | $249.00 |
| Individual modules: ESV / NRSVue / Webster / GNT-TRS / CUVS / NKRV | $14.90–$19.90 |
| ESVS / NRSVueS (Strong's) | $19.90 |
| IVP New Bible Commentary | $39.90 |
| ISBE | $49.90 |
| **BDAG + HALOT add-on** | **$179.00** |
| Academic Blue L1 / L2 / L3 | $400 / $850 / $1,000 |
| Academic Amber L1 / L1 Faculty | $998 / $1,098 |
| Seminary Promotional Bundle | $300.00 |
| Crossover: Preacher/Teacher Reference Library | $1,499 (stated value $7,500) |
| Crossover: Student/Scholar Biblical Language Bundle | $399 (stated value $2,100) |
| Crossover: Advanced add-on | $499 (stated value $2,100) |
| Switcher discount | 20% off, coupon `switchnow` |
| Wordsearch / BibleWorks crossover (historical) | $999 / $399 |

Their positioning is explicitly anti-subscription: *"Complete Feature Access, No Subscriptions… no hidden costs. Every tool and resource are yours forever."* And: *"Unlike some of our competitors, we don't make you pay extra to access advanced features."*

---

## 2.E What is good, what is bad

### Genuinely excellent
1. **The highlight system.** Covered above. Five separate wins in one feature: definable styles, multiple swappable files, cross-translation persistence, `[STYLE]` searchability, total reversibility.
2. **Click-bound dictionary linking.** Linked lexicon follows the word you *click*, not your scroll. Strictly more useful than milestone-syncing.
3. **Triple-click / double-click-Amplify / Live Click.** A three-tier progressive disclosure from a tap, to a targeted tool picker, to a fan-out search across the whole library. This is the best text-interaction model I found.
4. **Autocomplete for the entire search language.** The Quick Entry drop-down lists valid commands as you type. Powers users get a command line; everyone else gets a menu. Logos makes you learn `NEAR`/`WITHIN`/`@` from documentation.
5. **Range + Scope buttons on every search.** "Chapter / Verse / Clause / Sentence / Paragraph / Book" in one click. Nobody else exposes clause/sentence/paragraph granularity this cleanly.
6. **Versification mismatch surfaced, not hidden.** Re-scoped parallel panes + "make it the search text." Honest handling of a genuinely hard problem.
7. **Custom Phrasing.** Line breaks and indents inside a biblical text for chiasm/discourse analysis.
8. **Easy Answers.** Editable fields embedded in workbooks. A study tool that lets you *write in the book*.
9. **User Dictionaries / User Commentaries.** Lets users extend the system rather than just consume it.
10. **In-text integration as a stated philosophy:** "run a search, look up a definition, open a map, view a Timeline, find parsing information, or hear an audible pronunciation simply by selecting a portion of Bible text and then choosing the respective icon in the toolbar."
11. **Semantic Library taxonomy** (Texts / Tools / Databases / Parallels / Background / Visual).
12. **"No subscription, own it forever"** as an explicit, well-argued market position.
13. **Fast.** Speed is the headline claim ("Don't blink or you'll miss it… hitting the Enter key displays search results rather than a 'thinking' animation") and users corroborate it: *"I can look up information while leading a class discussion without lags or buffering time getting in the way."*
14. **Documentation depth in text.** Some of their support articles are outstanding (the missing-verses article, the hypertext-links article, the highlighting article) — real explanations of *why*.

### Dated, confusing, or broken
1. **Sync is the single worst thing about Accordance right now.** Removing Dropbox in 14.1 without a working replacement caused real data loss. From the iOS review feed, unedited:
   - *"Sync has been broken for MONTHS… I currently cannot sync notes or highlights between devices… support tickets are going unanswered and the iOS app has not been updated in 9 months. Support forums haven't had a response by Accordance personnel in nearly a year."*
   - *"It's been years (and a few updates) since I could edit a note on an iOS device. With the update of the desktop version of Accordance, multiple users… report that it is no longer possible to sync the iOS and desktop apps."*
   - *"I have lost all of my highlighted verses on the desktop app… The notes on my iPhone app are all messed up."*
   - *"Organizing folders is extremely Buggy!!!… synchronization is garbage and almost always fails."*
   This is the most damning finding in the whole research. **Whatever you build, losing a user's highlights on a version upgrade is existential.**
2. **Mobile is a companion, not a peer.** `Has little to no parity with the desktop app`; Greek/Hebrew word search fails on mobile; can't edit User Tools on iPad; can't make sermon documents; all Parallels modules are "(not for Mobile)".
3. **No tabs on mobile.** The most repeated single request. *"Give us tabs! Right now the most you can have open is 2 panes. If we could have tabs for text and then search and then lexicons, etc that would be amazing."* Desktop has tabs and zones; mobile has a two-pane split. This is an *artificial* limitation, not a platform constraint.
4. **Release cadence has collapsed.** v14 shipped Nov 2022; 14.1 in Sept 2025; **14.2 still unreleased** — the homepage currently carries a banner: *"macOS 27 Golden Gate is available for Mac Users. Accordance is currently working to ensure full compatibility… and we advise our users to wait to update their devices until we release Accordance version 14.2."* That's a 3-year gap between major versions with the OS compatibility story still open. Users: *"development has slowed down considerably"*; *"Rarely update their software."* Their own support site has promoted articles named *"Quick Fix for Search Results in 14.1"* and *"Issue: Problems with scrolling lists (such as the Add Parallel) list on Windows 10/11."*
5. **Windows is the second-tier platform.** Known-issue articles are Windows-specific (frozen content updates, broken scrolling lists). Review: *"Accordance constantly crashed. Support wasn't helpful, nor did they acknowledge the issue. Windows was always up to date."*
6. **Account creation and login failures, with no recovery path.** Multiple 1★ reviews: *"Can't create account… they do not provide any way to further trouble shoot nor do they provide a place to change your password."* *"Can I use the exact username and password that I use on Windows only to be told that the username or password is invalid when using the app. The app is useless to me if I cannot login."* The app's own support button "goes to a forum page not an email." **This is the most fixable and most embarrassing failure mode.**
7. **A Mac Catalyst/iPad-on-Mac listing that just shows the EULA.** 1★: *"This shows up in the APP store for my MAC BOOK PRO, but it doesn't work. It just displays the EULA and sits there."* They do have a known-issue article about the EU App Store.
8. **Video-only documentation.** I verified that a large fraction of their support articles — the entire "Lighting the Lamp" series, "QuickTip: …", "Quickstart", "Accordance Basics: …" — have **literally empty text bodies**; they are video embeds. That's inaccessible, unsearchable, and untranslatable. Logos's equivalent articles are all substantive text.
9. **No custom reading-plan builder.** You get shipped devotionals and chronological readings; you cannot say "read X for 20 minutes a day, starting Tuesday."
10. **Modular pricing confuses newcomers** — third-party review: *"Walk into Logos and you buy a 'base package.' Walk into Accordance and you assemble a library… The à la carte approach is the right model if you know what you want — and the wrong model if you don't."*
11. **Android is clearly second.** Min Android 8.0, and a documented "Known Issue: Android App and Google Play" where the app fails to appear on Play for some users.
12. **Small bugs that chip away at trust** — split-screen divider won't stay where you put it; loses your place when you switch apps; 5–7 second cold starts; text won't respond to book/chapter/verse taps so you must type the reference; a curly-quote HTML bug that made any module with an apostrophe in its title unselectable (reported to have locked out the Strong's Greek and Hebrew dictionaries); module downloads fail "especially if you want to do it in large batches"; note files corrupting and breaking hyperlinks.
13. **Tiny brand decisions that generate1★ reviews.** The app icon was changed from brown/orange to white/red and generated multiple 1★ reviews from long-time users, one from a graphic designer.
14. **Full app icon / branding churn on Mac broke some people's setups** ("On the Mac desktop, I was able to change the app icon back to the old one").

---

# 3. Cross-cutting conclusions for a new Bible reader app

### Steal these, from both

| Idea | Source | Why it wins |
|---|---|---|
| Reference-scoped highlights that appear in **every** translation | Accordance | Switching versions never loses your markup |
| User-defined highlight styles with **patterns + intensity**, in **multiple swappable files**, searchable via `[STYLE]` | Accordance | Turns markup into a thematic index; costs nothing to build |
| Insights sidebar: commentary snippet that tracks your scroll **inside** the reading pane | Logos | Zero-navigation glance on a phone |
| Word-level text diff with blue differences + hover base + inline strikethrough | Logos | Real tool, not a gimmick |
| Translation-similarity visualization (cluster graph / version river) | Logos | Turns "which translation" into a visible question |
| Morphology as a **grid**, with visual OR-grouping and negation | Logos / Accordance | Non-programmers can build real morph queries |
| Autocomplete listing every valid search command | Accordance | Command line power + menu accessibility |
| One-click Range + **Scope** (chapter/verse/clause/sentence/paragraph/book) | Accordance | Exposes granularity nobody else shows |
| Triple-click → Amplify → Live Click escalation | Accordance | Perfect progressive disclosure for word lookup |
| Click-bound dictionary linking (not scroll-bound) | Accordance | More precise than milestone sync |
| Custom line breaks / indents in the biblical text | Accordance | Chiasm and discourse analysis, unique |
| Editable answer fields inside workbooks | Accordance | Lets users *write in* the book |
| Camera reference scanner → multi-ref list → Passage List | Logos | Genuinely delightful; nobody else has it |
| Reading-plan ribbons in the text + calendar export + reminders | Logos | Habit formation where the reading happens |
| AI credits with a persistent meter; Smart Search as an *additional* mode | Logos | Correct way to ship metered AI |
| A free tier that genuinely works, with a documented promise it stays | Logos | Real top-of-funnel |
| Semantic library taxonomy (Texts / Tools / Parallels / Background / Visual) | Accordance | The module list is understandable |
| Surfacing versification mismatch instead of blanking a verse | Accordance | Honest handling of a hard problem |

### Avoid these — all observed failures1. **Ads in a paid product.** The single most damaging thing Logos does.
2. **Removing or replacing the user's established navigation without versioning.** Logos' v53 mobile release is the canonical cautionary tale.
3. **Removing a sync mechanism before the replacement works.** Accordance 14.1 / Dropbox is the canonical cautionary tale. Users reported losing years of highlights.
4. **Platform feature fragmentation presented as "the same product."** Logos's own 90-row matrix admits mobile lacks corresponding notes, highlight labels, reading-plan creation, and printing.
5. **AI displacing deterministic search.** Both "AI interferes with word search" and "they replaced the search engine with pay-to-play" complaints come from the same design error.
6. **Making login failure unrecoverable.** Multiple 1★ reviews from both apps; Accordance's is worse because there's no in-app password reset and the support button opens a forum.
7. **Publishing only video for documentation.** Accordance's empty-bodied support articles.
8. **A combinatorially exploding pricing matrix.** Tracks × tiers × denominations × years.
9. **Two-pane-only mobile with no tabs.** An artificial cap that users route around by asking loudly for tabs.
10. **Requiring a network for search when the text is already on the device.** Logos mobile cannot do full-library search, Passage Guide, or Word Study offline. Accordance desktop needs no network at all — that's the better default.

### Where the two products genuinely disagree, and which I'd side with

| Question | Logos | Accordance | My take |
|---|---|---|---|
| Own vs. subscribe | Subscription for features, books yours forever | Own everything, no subscription | **Accordance**, for trust. Logos's 24-month Legacy Fallback is a good-faith compromise but requires understanding it. |
| Mobile vs. desktop | Same account, reduced feature set, streaming | Same account, genuinely companion-only, offline-capable | Neither. Ship parity for *reading*, be explicit about what needs desktop. |
| Commentary access | Insights Panel inline in the reading pane | Adjacent parallel pane | **Logos**, for phone. Parallel panes win on desktop for depth. |
| Word lookup | Information Tool + Lexicon link sets | Triple-click / Amplify / Live Click | **Accordance**, clearly. |
| Highlighting | Notebooks + labels (desktop only) | Multi-file styled highlights, cross-version, searchable | **Accordance**, clearly. |
| Mobile free tier | 40+ free Bibles, real tools, documented permanence | Free app + ~60 free modules incl. Strong's + Mounce + KM | Tie, slight edge to Accordance on content, to Logos on tooling. |

---

## 4. Conflicts and things I could not verify

**Source conflicts flagged:**
- **Accordance Basic Starter: $49 vs $49.90.** Homepage and trial page say "$49"; the shop lists "$49.90." Both from accordancebible.com.
- **Logos tier naming.** The iOS App Store description says *"optional subscription plans called Logos Plus and Premium"*, and the Reference Scanner support doc says *"Available in Logos Plus and higher"* — but the actual tiers are **Premium / Pro / Max** (confirmed by the About panel article and logos.com). Stale copy in two live places.
- **Logos monthly Pro price.** kevinpurcell.org (Nov 2024) says Pro $14.99/mo, Max $19.99/mo; genewhitehead.com quotes $12.50/mo for Pro "billed annually." These are **consistent** once you separate monthly from annual-effective, but secondary sources disagree on which number to lead with. Annual ($99.99 / $149.99 / $199.99) is confirmed by the logos.com subscription page snippet.
- **Accordance subscription?** learnofchrist.com's Accordance review claims *"new Accordance subscription from ~$9.99/mo"* and describes an "Original Languages bundle ~$500–$1,500." **I found no evidence of any Accordance subscription** — the crossover page explicitly promises "no subscriptions." Treat that review as unreliable (it also mis-describes module pricing as ~$200 "Starter Collection" when the real starter is $49–$99.90).

**Could not verify:**
- The Reddit thread on the Logos subscription transition and any `community.logos.com` forum content (both 403).
- Current Logos **desktop** marketing version number. The About-panel doc uses "48.0" as an example; Kevin Purcell wrote "version 37" at the 2025 launch; I could not confirm today's number.
- Accordance **14.2** release contents or date; Android current version (site still cites Android 2.2.3 and min Android 8.0; Play Store listing unreachable).
- Accordance's exact syncable file-type list beyond User Notes / User Tools / Highlights files / My Places / Preferences / Papers.
- Whether Accordance study-Bible footnotes render inline in the pane or in a separate pane — the architecture strongly implies separate panes, but I found no first-party statement.
- Whether Logos verse numbers render as inline superscripts or in a gutter.
- The exact contents of the "Legacy Fallback License" tier-by-tier feature set (the logos.com FAQ answers are JS-rendered and would not render).

**One methodological caveat:** logos.com prices, library tables, and the subscription FAQ answers are rendered client-side and did not appear in raw HTML. Where I could only get prices from search-result snippets or third parties, I have said so inline.