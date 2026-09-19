# Obsidian-Vault — LLM wiki

Schema for this vault. The workflow lives in the `llm-wiki` skill; this file holds the registry and this vault's conventions.

## Layers

- `raw/` — source identity, written once, then read-only. Carries no `type`: it is identity, not a knowledge page.
- `sources/` — one record per chapter or article: what the text says, and where. No claims.
- `wiki/` — knowledge pages, flat, typed by frontmatter.
- `views/` — one `.base` per type, built in Obsidian's UI. `index.md` is the hub: it lists the bases, and it is what gives the folder a page on the site (a folder of only `.base` files has none).
- `templates/` — page shapes; human-owned; never published.
- `index.md` — the front door. Everything between `<!-- hero:start -->` and `<!-- hero:end -->` is frozen.

## Registry

Accepted page types. A type enters only when the human accepts it, carrying its question, failure test and required slots.

- **`source`** — what a text says, and where. Fails when a quote is not verbatim or an anchor breaks. Slots: `§ map` · `Entries · Glossary`.
- **`book`** — a book's hub: progress, chapters, what each chapter produced. Fails when the inventory misses something a chapter produced. Slots: `progress` · `chapters` · `yield` · `shape notes`.
- **`concept`** — a distinction, with its contrast. Fails when the contrast is wrong. Slots: `distinction` · `contrast` · `per-source usage` · `the human's position`.
- **`person`** — who someone was here, and what they held. Fails when a position is attributed to the wrong person. Slots: `stance` · `what this book does with them` · `contrast` · `wording warnings`.
- **`argument`** — whether a conclusion holds. Fails when an inference step does not follow, a ground is misread, or the falsifier is already met. Slots: `C` · `G` · `W` · `I` · `S` · `R`.
- **`take`** — what the human makes of this. Fails when it is no longer what they think. Slots: `position` · `what it opposes` · `open or settled`.

Proposed, not yet accepted: `practice`, `mechanism`, `trace`.

Per-book shape notes live in that book's `book` hub. They may add or rename slots — never drop a registry slot.

## Conventions

- **Frontmatter**: `type`, `gist`, `tags`, `sources`, `updated`, `quotes_check`, `aliases`, `publish`. `gist` is the page's claim in one breath — what a `Produced` block shows so a chapter reads as a yield, not a list of names. Tags are English keys; `type` comes from the registry.
- **Publish**: `true` for sources, books and knowledge pages; `false` for takes. `templates/` and `private/` never publish.
- **Wording — keys English, prose in the source's language.** A term or a person is named by its English canonical form (`monism`, `Vico`, `spectacles-of-categories`), with the source's own word in `aliases`; when no English name exists, the source's word is the key. Everything the text *says* — claims, argument names, chapter and book titles, quoted `§` titles — keeps the source's language, because that is the book talking, not the wiki filing it. Structural keys are English throughout: frontmatter, type names, tags, slot headings, the honesty tags `[stated]` / `[reconstruction]` / `[quote]` / `[paraphrase]` / `[mine]`.
- **Quotes**: verbatim only after a same-run check against the text; one home per quote — a second page cites, never copies. The count lives in `quotes_check`.
- **No `log.md`**: chronology is `git log`, the quote audit is frontmatter.
- **Reading is the human's**: pace, dialogue, and how much gets read together are not the agent's to set.

## In flight — deliberately not migrated

- Root legacy notes — `Xv6-OS-Notes.md`, `Philosophy-of-SoftwareDesign.md`, the logic notes. They stay where they are until a question touches them.

`reading/观念的力量/` was the old per-book shape (per-book `AGENTS.md`, `index.md`, `log.md`, `concepts/`, `persons/`). Its two chapters were migrated into the shape above on 2026-09-19; the folder is gone.
