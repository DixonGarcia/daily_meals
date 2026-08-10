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

### Step 3: Update Lifecycle State on the Spec Branch
Update `_product/current.yml` before merging so the state change is included in the merge commit:
```bash
git add _product/current.yml
git commit -m "chore: advance lifecycle state to build-feature"
```

### Step 4: Merge Spec Branch into Main
```bash
git checkout main
git merge --no-ff spec/<FEAT-XX>-<slug> -m "merge(spec): integrate FEAT-XX spec into main"
```
> `--no-ff` (no fast-forward) creates an explicit merge commit, keeping spec work visible as a discrete unit in history.

### Step 5: Delete the Spec Branch
Once merged, the spec branch is no longer needed:
```bash
git branch -d spec/<FEAT-XX>-<slug>
```

### Step 6: Confirm to the User
Reply confirming:
1. Branch `spec/<FEAT-XX>-<slug>` was merged into `main`.
2. The spec branch was deleted.
3. `_product/current.yml` shows `current_step: build-feature`.
4. `main` is now ready for the `build-feature` skill to branch off from.
