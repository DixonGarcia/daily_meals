---
name: merge-spec
description: Merges the spec branch into main after the mockup has been approved via choose-mockup. Runs between choose-mockup and build-feature.
---

# Merge Spec Branch (`merge-spec`)

Use this skill **after `choose-mockup`** completes and the user has confirmed the winning mockup variant. This skill merges the `spec/<FEAT-XX>-<slug>` branch into `main` so that the approved specification lives on the main branch before implementation begins.

---

## 🚫 Hard Constraints

- **Do not run before `choose-mockup`** — A mockup must be selected and the discarded variant deleted before merging.
- **Do not start implementation** — This skill only merges the spec branch. Coding begins in `build-feature`.
- **Never force-push** — Use a standard merge commit to preserve history.

---

## 🚀 Step-by-Step Workflow

### Step 1: Verify the Spec Branch is Clean
Confirm there are no uncommitted changes on the current `spec/<FEAT-XX>-<slug>` branch:
```bash
git status
```
If there are uncommitted changes (e.g., from the mockup selection cleanup), commit them first:
```bash
git add _product/<domain>/
git commit -m "spec(<domain>): record winning mockup variant selection"
```

### Step 2: Merge Spec Branch into Main
```bash
git checkout main
git merge --no-ff spec/<FEAT-XX>-<slug> -m "merge(spec): integrate FEAT-XX spec into main"
```
> `--no-ff` (no fast-forward) creates an explicit merge commit, keeping spec work visible as a discrete unit in the history.

### Step 3: Delete the Spec Branch
Once merged, the spec branch is no longer needed:
```bash
git branch -d spec/<FEAT-XX>-<slug>
```

### Step 4: Confirm to the User
Reply confirming:
1. Branch `spec/<FEAT-XX>-<slug>` was merged into `main`.
2. The spec branch was deleted.
3. `main` is now ready for the `build-feature` skill to branch off from.
