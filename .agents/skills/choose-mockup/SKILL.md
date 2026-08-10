---
name: choose-mockup
description: Guide for presenting mockup variants to the user, recording their choice, deleting the discarded mockup variant file, and updating the mockup index to reflect the winning layout.
---

# Choose a Mockup Variant (`choose-mockup`)

Use this skill when the user is ready to review the designed mockup variants for a feature, select the preferred option, delete discarded options, and proceed to implementation.

---

## 🔄 Lifecycle State

**This is Step 2 of the feature lifecycle.**

**Prerequisite check** — Before proceeding, read `_product/current.yml` and verify:
```bash
cat _product/current.yml
```
- The file exists (a feature is in progress).
- `lifecycle.build-spec.status` is `done`.
- `current_step` is `choose-mockup`.

If the prerequisite is not met, stop and tell the user which step needs to be completed first.

**After completing**, update `_product/current.yml`:
- Set `lifecycle.choose-mockup.status` to `done` and add `completed_at: "YYYY-MM-DD"`.
- Set `current_step` to `merge-spec`.

---

## 🚫 Hard Constraints

- **Never decide for the user** — The agent must never choose which mockup to keep. Always ask the user explicitly.
- **Do not edit core design parameters** — Do not alter the selected variant's core visual design rules during selection.
- **No implementation actions** — This skill is strictly for selecting a mockup, updating the specification, and cleaning up discarded mockups. Do not start coding until specified.

---

## 🚀 Step-by-Step Workflow

### Step 1: Verify Lifecycle State
Read and validate `_product/current.yml` as described above.

### Step 2: Identify Mockup Files
Locate the mockup files under the target domain directory:
```
_product/<domain>/mockups/
```
Identify the files for **Variant 1** and **Variant 2** (e.g., `variant_1_list.html` vs. `variant_2_card.html`). Also verify that a central index file exists: `_product/<domain>/mockups/index.html`.

### Step 3: Present Choices to the User
Ask the user (or use the `ask_question` tool) to select their preferred layout. Present both variant names and a short description of their differences.

### Step 4: Record the Decision, Cleanup Discarded Mockups & Update Index
Once the user responds with their selection (e.g., "Variant 2"):

1. **Document Selection** — Record the chosen mockup layout in `overview.md` (add or update the `## 6. Selected Variant` section).
2. **Delete Discarded Mockup(s)** — Delete the HTML mockup file(s) for the unselected variant(s):
   ```bash
   rm _product/<domain>/mockups/variant_1_list.html
   ```
3. **Update Mockup Index** — Update `_product/<domain>/mockups/index.html` to display only the winning mockup option, clearly indicating it is the selected layout.
4. **Provide Link** — Provide the clickable link to the central mockup index:
   ```
   [mockups/index.html](file:///absolute/path/to/_product/<domain>/mockups/index.html)
   ```

### Step 5: Update Lifecycle State
Update `_product/current.yml` on disk to mark `choose-mockup` as done and advance `current_step` to `merge-spec`. Then commit the mockup selection changes:
```bash
git add _product/<domain>/
git commit -m "spec(<domain>): select winning mockup variant"
```
