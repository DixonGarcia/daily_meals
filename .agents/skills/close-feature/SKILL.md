---
name: close-feature
description: Mandatory last step of every feature or fix cycle. Writes a prose entry in History.md, merges the feat branch into main, deletes implementation artifacts, and removes the lifecycle state file.
---

# Close a Feature (`close-feature`)

**This step is mandatory and cannot be skipped.** It must run as the final action after every `build-feature` or significant fix cycle is complete and all specs are green.

---

## 🔄 Lifecycle State

**This is Step 6 (final) of the feature lifecycle.**

**Prerequisite check** — Before proceeding, read `_product/current.yml` and verify:
```bash
cat _product/current.yml
```
- The file exists.
- `lifecycle.review-implementation.status` is `done`.
- `current_step` is `close-feature`.

If the prerequisite is not met, stop and tell the user which step needs to be completed first.

**At the end of this skill**, `_product/current.yml` is deleted — it is the signal that no feature is currently open. The permanent record is in `History.md`.

---

## 🚫 Hard Rules

- **Never skip this step.** If a new feature is requested, you MUST verify that `_product/current.yml` does not exist (or that all steps are `done`) before starting.
- **No bullets in History.md entries.** Dense prose only — 1 to 3 paragraphs per entry.
- **No relative dates.** All dates must be ISO 8601 absolute format: `YYYY-MM-DD`.
- **Real names only.** Use actual class names, table names, file names, and route paths — never vague descriptions.
- **Do not invent.** Write only what was actually implemented and tested.
- **English only.** `History.md`, skills, and agent files must be written in English.

---

## 🔢 ID Convention

Every feature or fix must carry a sequential ID prefix:

- New capabilities → `FEAT-XX` (e.g., `FEAT-01`, `FEAT-02`)
- Bug fixes or patches → `FIX-XX` (e.g., `FIX-01`, `FIX-02`)

Read the feature ID from `_product/current.yml` (`feature.id`).

---

## 🚀 Step-by-Step Closing Workflow

### Step 1: Verify All Tests Pass
Run the full test suite. Do not close the feature if there are failures.
```bash
bundle exec rspec
```

### Step 2: Verify Lifecycle State
Read `_product/current.yml` and confirm `review-implementation` is `done` (see Lifecycle State section above).

### Step 3: Append the History.md Entry
Append a new entry at the **top** of `History.md` (newest-first) using this exact structure:

```markdown
---

## [FEAT-XX | FIX-XX] Short Title — YYYY-MM-DD

Paragraph 1: What problem was solved or what capability was added. Mention the domain, the business need, and the user-facing outcome.

Paragraph 2: Which classes, tables, controllers, routes, or services were created or modified. Be specific — use real names like `ApiKey`, `api_keys`, `Api::V1::BaseController`, `/api/v1/dishes`.

Paragraph 3 (optional): Notable design decisions, constraints, or deviations from the original spec. Include test coverage summary (number of examples, 0 failures).
```

### Step 4: Delete Implementation Artifacts
Once the code exists, `implementation.md` (the "how" scaffold) and `mockups/` (the visual proposals) are redundant — the design intent now lives in the code:
```bash
rm _product/<domain>/implementation.md
rm -rf _product/<domain>/mockups/
```
> **Keep**: `overview.md` (business context, permanent).

### Step 5: Commit, Open Pull Request, Verify CI, and Merge into Protected Main
```bash
# Delete the state file from disk (gitignored, never tracked)
rm _product/current.yml

# Commit History.md update and artifact deletions
git add History.md _product/<domain>/
git commit -m "chore: close FEAT-XX — History.md entry and spec artifacts removed"

# Push the feature branch and open a Pull Request against protected main
git push -u origin feat/<FEAT-XX>-<slug>
gh pr create --base main --title "feat: FEAT-XX <short title>" --fill

# Wait for required GitHub Actions status checks (scan_ruby, lint, test) to pass
gh pr checks --watch --fail-fast

# Merge the Pull Request (creates a merge commit on main and deletes the remote branch)
gh pr merge --merge --delete-branch

# Sync local main
git checkout main
git pull --ff-only
```

### Step 6: Confirm Closure
Reply to the user confirming:
1. The `History.md` entry was written (include the ID and title).
2. `implementation.md` and `mockups/` were deleted from `_product/<domain>/`.
3. `_product/current.yml` was removed — no feature is currently open.
4. Branch `feat/<FEAT-XX>-<slug>` was merged into `main` and deleted.
5. The next available feature ID (e.g., "Next: FEAT-04").

---

## 📄 History.md Format Reference

```markdown
# History

Development log for DailyMeals. Entries are newest-first. Each entry covers one logical feature or fix cycle.

---

## [FEAT-01] Short Title — YYYY-MM-DD

Prose paragraph...

---

## [FEAT-02] Another Title — YYYY-MM-DD

Prose paragraph...
```

---

## ⚠️ Pre-Feature Checklist (enforced before `build-spec`)

Before starting any `build-spec`, the agent must:
1. Confirm `_product/current.yml` does **not** exist (no open feature).
2. Read `History.md` to find the next sequential ID.
3. If `current.yml` exists → read it, identify the blocked step, and resolve it before proceeding.
