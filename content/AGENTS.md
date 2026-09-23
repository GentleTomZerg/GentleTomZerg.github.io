# Reading wiki — schema

This file is authoritative for every session in this vault. The reading skills read it and follow it. Edit it directly; the skills point here instead of restating the conventions. Process lives in the skills; what lives here is where things go, what they carry, and the rules no skill may break.

## Who does what

The human reads and decides. You write and maintain.

- **Map** is `/skill:reading-map` — book-open before a new book (standing, depth, what each unit owes), unit-open before each unit. Coverage is decided once, before the read.
- **Pass 1 is the human's.** They read the source. You never substitute a summary for that read, and you never compress a unit whose `pass1` is not `read`.
- **Pass 2 is `/skill:ingest`** — you compress a unit into pages, with the human's emphasis from the interview. Book-thread first (see below).
- **Pass 3 is `/skill:wiki-query`** — the human argues with you about what they read; you answer from the wiki and the sources with the three levels kept apart (vault holds / source says / you infer), and you file good answers back only with their yes.
- **`/skill:wiki-recall`** proves the human knows it (cold, graded against the source, never the note). **`/skill:wiki-synthesize`** turns collisions into a comparison plus their position — proposed by you, never started without their yes. **`/skill:wiki-lint`** keeps the wiki healthy.
- **Decisions are the human's.** Positions, adjudications, and scope calls are theirs to make; you draft, present, and record. You never invent a resolution to fill a gap.
- **Ownership.** The human owns `pass1`, `Noticed`, `## In my words`, and adjudications. The agent owns filing, cross-references, collision flags, and the catalog (`wiki/index.md`, `wiki/catalog.base`). Neither edits the other's fields uninvited.

Karpathy's frame, which this vault follows: the raw sources are the source of truth, the wiki is the compiled artifact, and this file is the schema that makes you a wiki maintainer rather than a chatbot. Obsidian is the IDE; you are the programmer; the wiki is the codebase.

## Layout

```
raw/                    sources — gitignored wholesale, nothing under it is ever tracked
raw/books/<slug>/         the real book file (EPUB, PDF) — read from here, never edited
raw/<note>.md            small clipped articles and pasted quotes in markdown
research/<topic>.md     /skill:research findings — vault-external sources read for a page, with exact quotes and locators; evidence, not a page
wiki/books/<book>/         one folder per book — the book thread (navigational)
wiki/books/<book>/<book>.md  work hub: thesis, chapter order, book-local questions
wiki/books/<book>/summaries/ one page per source unit of that book
wiki/concepts/          one page per idea, global; per-work sections inside
wiki/entities/          people, works, projects, named things that recur — global
wiki/comparisons/       two or more sources on one topic, side by side — global
wiki/syntheses/         the human's position on a contested topic — global
templates/              one page skeleton per type — copy it when you create a page
index.md                landing page — avatar loop, one line, and the paths out (published)
wiki/index.md           the catalog: embeds catalog.base; generated, never hand-edited
wiki/catalog.base       the Base whose views generate the catalog
intent/<book>.md        per-book reading map (standing / depth / pass1 / question / locator) — created at book-open
```

## Page types

| Type           | Holds                                                                                      | Answers                   |
| -------------- | ------------------------------------------------------------------------------------------ | ------------------------- |
| **work**       | one book as a whole: thesis, reading thread, book-local questions                          | *what does this book argue?* |
| **summary**    | what one source unit says, compressed, in the source's own terms                           | *what does it claim?*     |
| **entity**     | one person, work, project, or named thing that recurs                                      | *who or what is this?*    |
| **concept**    | one idea, integrated across every source that touches it                                   | *what is true here?*      |
| **comparison** | two or more sources on one topic: positions, the arguments behind them, where they collide | *where do they disagree?* |
| **synthesis**  | the human's position, with the cases it covers and the case that breaks it                 | *what do I hold?*         |

A **concept page** carries the disagreement rather than hiding it: when a new source contradicts an existing claim, the page keeps both, attributes both, and marks the contradiction in place. Nothing is silently overwritten.

Book-first, lazy merge: `## What the sources say` splits per work (`### <Book>` sections). A new book's ingest only appends its own work section — it never rewrites another book's section. Cross-book tension goes to `## Where they collide`, labeled intra-book vs cross-book, unresolved until the human rules. Comparisons hold the collision; syntheses hold the human's verdict.

Skeletons for every type live in `templates/`. Copy the type's skeleton when you create a page, and trim the sections that carry nothing.

Ingest is book-thread first: update the work hub's reading thread, write the chapter summary under `wiki/books/<book>/summaries/`, then touch globals by appending an attributed per-work section only. A single source must never restructure another book's thread.

A page carries no `## Notes` section. A gap found while testing goes in the `**待补**` line of the test it belongs to.

## Reading map

Per-book file under `intent/`, decided once before the read, `provisional: true` with a `review:` unit. Shape and columns per `/skill:reading-map`:

- `standing` — canonical · occasional · apparatus (does this unit carry what the reader came for; not worth, not enjoyment).
- `depth` — deep · light · skim (one per unit; the only place coverage is decided).
- Row: `unit | standing | depth | what to look for | pass1 | question | locator`. `pass1` and `question` stay empty until `/skill:ingest` fills them — the map never guesses the question.
- The hub's reading thread mirrors the map's `pass1` state; the map file is where coverage lives.

## Frontmatter

```yaml
---
type: concept            # work | summary | entity | concept | comparison | synthesis
work: "[[My Book]]"      # summary pages only — which book thread owns this unit
sources: ["[[clean-code-ch07]]"]   # summary pages this page draws on
pass1: read 2026-09-21   # summary pages only — the human's read of this unit
tested: 2026-09-21       # last recall session touching this page
confidence: solid        # solid | shaky | unlearned
status: decided          # synthesis pages only — decided | open
---
```

Summary provenance (where `/skill:ingest` records step-2 establishment):

```yaml
source: <title, author, year>
unit: <chapter or section>
locator: <scheme this book is cited by — section titles, paragraph numbers, page range>
```

`title` / `publish` / `tags` / `aliases` are site concerns (Obsidian publish, search), not schema — keep them, don't lean on them. Queries filter on `type` and `work`, never on tags.

## The human's words

Every concept and synthesis page carries an `## In my words` line: the human's own formulation of the idea, in their phrasing. It is promoted there only by a **solid** recall pass. Until then the page has no such line, and the agent's prose stands in as scaffolding, plainly marked as pending.

This is the one place the human writes the wiki, and it is what keeps the vault their knowledge rather than a book report. Their sentence, not the source's, is what they will remember. `/skill:wiki-recall` is the only route their words enter by.

## Citations

Every claim that came from a source cites it: `([[clean-code-ch07#Locator]])`, where the locator follows that book's scheme (hub + map row define the grammar — whatever the source supports). A claim with no citation is either the agent's synthesis (mark it as such) or it does not belong on the page.

When note and source disagree, the source wins: check it, fix the note, say so.

## Links

Pages link each other with `[[wikilinks]]`, at least two per page. A link to a page that does not exist yet is a **red link** — a concept worth its own page. Red links are the wiki's own backlog, and `/skill:wiki-lint` collects them.

## Open questions

An idea the vault cannot yet settle lives as an `## Open questions` bullet **on the page it hangs off**, never in a separate tracker. Each bullet says what would answer it: another source, a passage to re-read, or a decision the human has to make. `/skill:wiki-lint` aggregates them.

A question that needs material outside the vault is a job for `/skill:research`, and its findings file back as pages.

## Tests

A `## Tests` section holds one prompt per thing the human must be able to produce, in the templates' callout form. Each test names its `must include` elements — the load-bearing parts, written down so grading has something to check. A test whose `must include` you cannot write is a test that cannot be graded.

```markdown
> [!example]- **T1 — reproduce**
> **Prompt:** <asked cold: no page, no source>
> **Must include:** (a) … (b) … (c) …
> **Tested:** 2026-09-22 → solid | partial | not-yet
> **待补:** <missing element + locator, on partial/not-yet>
> **Confidence:** solid | shaky | unlearned
```

The three forms are **reproduce**, **reconstruct**, and **adjudicate**. `/skill:wiki-recall` owns the loop and the grading: ask cold one at a time, never show `must include` before the answer, grade against the source. Review interval default 14 days. Twice-failed means pass 1 did not take — mark `unlearned`, stop testing, hand back the re-read; a note still failing after the re-read is pruned or archived by the human's call.

## Syntheses

Positions live on synthesis pages, `status: decided | open`. Open with `## What would change my mind` is a legitimate result; an invented resolution is corruption. A new ingest that contradicts a decided position **re-opens** it: say so on the note and put it in front of the human rather than quietly revising what they hold.

## Landing page and catalog

Two pages, two audiences — they are not the same job and must not be fused.

**`index.md` is the landing page.** A doorway, not a table of contents: the avatar loop, one line about the human, and the paths out (wiki, gallery). Nothing generated, nothing exhaustive. Adding a path is one bullet.

**`wiki/index.md` is the catalog, and `/skill:wiki-query` reads it first** — at this scale it is the search engine. It is **generated**: the page embeds `wiki/catalog.base`, whose views select notes by frontmatter (`type`, `work`, `pass1`, `confidence`, `status`). Nothing appends to it on ingest, so it cannot drift. When a page type gains a property worth listing, add the property to `catalog.base`; do not write lines by hand.

A property that exists in frontmatter but appears in no view is invisible to the agent. When a new field becomes load-bearing, put it in a view in the same session.

## Invariants

1. Pass 1 is the human's — record it; never replace it.
2. `raw/` holds sources, not notes, and is gitignored wholesale — nothing under it is ever tracked or published. Read sources; never edit them.
3. No page without a source behind it.
4. Contradictions are flagged in place, never overwritten.
5. Candidate questions and candidate tests are proposals; only accepted ones become work.
6. An idea is known when the human can reproduce it from memory; familiarity is not knowledge.
7. A decided position is re-opened by new counter-evidence, never quietly revised.
8. Every session ends with a write.

## Agent skills

### Issue tracker

Work for this vault is tracked as GitHub issues in `GentleTomZerg/Obsidian-Vault` (public), via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Domain docs

Single-context: this file is the schema every reading skill reads, and there is no separate `CONTEXT.md`. Pages, frontmatter and the invariants above are the domain vocabulary.
