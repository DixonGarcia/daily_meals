---
name: choose-mockup
description: Guide for presenting mockup variants to the user, recording their choice, and preserving all variants for historical reference.
---

# Choose a Mockup Variant (`choose-mockup`)

Use this skill when the user is ready to review the designed mockup variants for a feature, select the preferred option, and proceed to implementation.

---

## 🚫 Hard Constraints

- **Never decide for the user** — The agent must never choose which mockup to keep. Always ask the user explicitly.
- **Do not edit the HTML** — The agent must not modify the content of any mockup files.
- **No implementation actions** — This skill is strictly for selecting a mockup and cleaning up the workspace. Do not start coding.

---

## 🚀 Step-by-Step Workflow

### Step 1: Identify Mockup Files
Locate the mockup files under the target domain directory:
```
_product/<domain>/mockups/
```
Identify the files for **Variant 1** and **Variant 2** (e.g., `variant_1_list.html` vs. `variant_2_card.html`). Also verify that a central index file exists: `_product/<domain>/mockups/index.html`.

### Step 2: Present Choices to the User
Ask the user (or use the `ask_question` tool) to select their preferred layout. Present both variant names and a short description of their differences.

### Step 3: Record the Decision and Confirm
Once the user responds:

1. Note the selected variant in `overview.md` and/or `implementation.md` (add a "Selected variant" section if not already present).
2. **Do NOT delete any mockup files.** Retain all variants in `_product/<domain>/mockups/` for historical context.
3. Provide the clickable link to the central mockup index so the user can open it in the browser:
   ```
   [mockups/index.html](file:///absolute/path/to/_product/<domain>/mockups/index.html)
   ```
4. Confirm to the user that the selection is recorded and all files are preserved.
