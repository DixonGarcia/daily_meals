---
name: choose-mockup
description: Guide for presenting mockup variants to the user, asking for their choice, and deleting the discarded mockup variant file.
---

# Choosing a Mockup Variant (`choose-mockup`)

Use this skill when the user is ready to review the designed mockup variants for a feature, decide on the preferred option, and clean up the discarded variant.

---

## 🚫 Key Constraints
* **Do not pick for the user**: The agent must never make the decision on which mockup to keep. Always ask the user.
* **Do not edit HTML**: The agent must not edit the HTML content of the mockups.
* **Do not trigger other implementation/coding actions**: This skill is strictly for selecting a mockup and cleaning up the workspace files.

---

## 🚀 Step-by-Step Selection Workflow

### Step 1: Identify Mockup Files and Overview Index
Locate the mockup files under the target domain directory:
`_product/<domain>/mockups/`

Identify the files belonging to **Variant 1** and **Variant 2** (e.g., `variant_1.html` vs. `variant_2.html`). Also verify that there is a central mockups index/overview file `_product/<domain>/mockups/index.html` (or `overview.html`) linking to both.

### Step 2: Present Choices to the User
Ask the user directly (or using the `ask_question` tool) to select their preferred mockup layout. Present the names and descriptions of both options clearly.

### Step 3: Document and Present Mockup Overview Index
Once the user responds with their selection (e.g., "Keep Variant 1"):
1. Mark the preferred mockup variant in `overview.md` and/or `implementation.md`.
2. Do **NOT** delete the discarded mockup files. Retain all variants in the `_product/<domain>/mockups/` folder for historical context and documentation.
3. In your response output, provide the clickable link (using standard markdown `file://` scheme) to the central mockup index file so that the user can open it in their browser (e.g., `[mockups/index.html](file:///path/to/mockups/index.html)`).
4. Confirm to the user that the selection has been noted and all files remain preserved.
