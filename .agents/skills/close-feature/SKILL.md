---
name: close-feature
description: Mandatory last step of every feature or fix cycle. Writes a dense prose entry in History.md, verifies no other feature is open, and deletes the implementation.md file from the spec folder.
---

# Closing a Feature (`close-feature`)

**This step is mandatory and cannot be skipped.** It must run as the final action after every `build-feature` or any significant fix cycle is complete and all specs are green.

---

## 🚫 Hard Rules

* **Never skip this step.** If a new feature is requested, you MUST verify that the previous feature is properly closed (its entry exists in `History.md`) before starting.
* **One open feature at a time.** Before running `build-spec` for a new feature, check `History.md` for any entry marked `[OPEN]`. If one exists, close it first.
* **No bullets in History.md entries.** Prose only — 1 to 3 dense paragraphs per entry.
* **No relative dates.** All dates must be ISO 8601 absolute format: `YYYY-MM-DD`.
* **Real names only.** Mention actual class names, table names, file names, and route paths — never vague descriptions.
* **Do not invent.** Write only what was actually implemented and tested.

---

## 🔢 ID Convention

Every feature or fix must carry a sequential ID prefix:

* New capabilities → `FEAT-XX` (e.g., `FEAT-01`, `FEAT-02`)
* Bug fixes or patches → `FIX-XX` (e.g., `FIX-01`, `FIX-02`)

The ID is assigned at the start of the feature (when `build-spec` runs) and carried through to the `History.md` entry header.

To determine the next ID, read the existing entries in `History.md` and find the highest number for each prefix, then increment by 1.

---

## 🚀 Step-by-Step Closing Workflow

### Step 1: Verify All Tests Pass
Run the full test suite. Do not close the feature if there are failures.
```bash
bundle exec rspec
```

### Step 2: Determine the Feature ID
Read `History.md` and find the last `FEAT-XX` or `FIX-XX` number to confirm the ID for this entry.

### Step 3: Write the History.md Entry
Append a new entry to `/History.md` (at the **top**, newest first) using this exact structure:

```markdown
---

## [FEAT-XX | FIX-XX] <Short Title> — YYYY-MM-DD

<Paragraph 1: What problem was solved or what capability was added. Mention the domain, the business need, and the user-facing outcome.>

<Paragraph 2: Which classes, tables, controllers, routes, or services were created or modified. Be specific — use real names like `ApiKey`, `api_keys`, `Api::V1::BaseController`, `/api/v1/dishes`.>

<Paragraph 3 (optional): Any notable design decisions, constraints applied, or deviations from the original spec. Include test coverage summary (number of examples, 0 failures).>
```

### Step 4: Delete implementation.md
The `implementation.md` file inside `_product/<domain>/` served as a scaffold guide. Once the code exists, it is redundant. Delete it:
```bash
rm _product/<domain>/implementation.md
```
> **Keep**: `overview.md` (business context, permanent) and `mockups/` (design history, permanent).

### Step 5: Confirm Closure
Reply to the user confirming:
1. The `History.md` entry was written (include the entry ID and title).
2. `implementation.md` was deleted.
3. The next available feature ID (e.g., "Next: FEAT-03").

---

## 📄 History.md Format Reference

```markdown
# History

Project development log for DailyMeals. Entries are newest-first. Each entry covers one logical feature or fix cycle regardless of commit count.

---

## [FEAT-01] <Title> — YYYY-MM-DD

Prose paragraph...

---

## [FEAT-02] <Title> — YYYY-MM-DD

Prose paragraph...
```

---

## ⚠️ Pre-Feature Checklist (enforced before `build-spec`)

Before starting any new `build-spec`, the agent must:
1. Read `History.md`.
2. Check if any entry ends with `[OPEN]` or if the last feature has no entry yet.
3. If an open feature is detected → **stop, close it first, then proceed**.
4. Confirm the next ID number to assign.
