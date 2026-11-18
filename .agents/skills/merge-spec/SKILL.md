---
name: merge-spec
description: Merges the spec branch into main after the mockup has been approved via choose-mockup. Runs between choose-mockup and build-feature.
---

# Merge Spec Branch (`merge-spec`)

Use this skill **after `choose-mockup`** completes and the user has confirmed the winning mockup variant. This skill merges the `spec/<FEAT-XX>-<slug>` branch into `main` so that the approved specification lives on the main branch before implementation begins.

---

## 🔄 Lifecycle State

**This is Step 3 of the feature lifecycle.**

**Prerequisite check** — Before proceeding, read `_product/current.yml` and verify:
```bash
cat _product/current.yml
```
- The file exists.
- `lifecycle.choose-mockup.status` is `done`.
- `current_step` is `merge-spec`.

If the prerequisite is not met, stop and tell the user which step needs to be completed first.

**After completing**, update `_product/current.yml`:
- Set `lifecycle.merge-spec.status` to `done` and add `completed_at: "YYYY-MM-DD"`.
- Set `current_step` to `build-feature`.
- Set `branches.spec` to `~` (the branch no longer exists).

---

## 🚫 Hard Constraints

- **Do not run before `choose-mockup`** — A mockup must be selected and the discarded variant deleted before merging.
- **Do not start implementation** — This skill only merges the spec branch. Coding begins in `build-feature`.
- **Never force-push** — Use a standard `--no-ff` merge commit to preserve history.

---

## 🚀 Step-by-Step Workflow

### Step 1: Verify Lifecycle State
Read and validate `_product/current.yml` as described above.

### Step 2: Verify the Spec Branch is Clean
Confirm there are no uncommitted changes on the current `spec/<FEAT-XX>-<slug>` branch:
```bash
git status
```
If there are uncommitted changes, commit them first:
```bash
git add _product/<domain>/
git commit -m "spec(<domain>): record winning mockup variant selection"
```

### Step 3: Update Lifecycle State
Update `_product/current.yml` on disk: set `merge-spec: done`, `branches.spec: ~`, and `current_step: build-feature`.
> This is a local disk write only — `current.yml` is gitignored and never committed.

### Step 4: Seal Approved Spec on the Feature Branch
Because `main` is protected by GitHub Branch Protection and the workflow uses a single Pull Request at the end of the feature cycle (`close-feature`), do **not** merge into `main` locally here. Keep working on `feat/<FEAT-XX>-<slug>` after confirming explicit user approval of the spec and mockup:
```bash
git status
```

### Step 5: Confirm to the User
Reply confirming:
1. The spec and winning mockup are approved and committed on `feat/<FEAT-XX>-<slug>`.
2. `_product/current.yml` shows `current_step: build-feature`.
3. The branch is now ready for the `build-feature` skill to begin TDD implementation.
