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

### Step 1: Identify Mockup Files
Locate the mockup files under the target domain directory:
`_product/<domain>/mockups/`

Identify the files belonging to **Variant 1** and **Variant 2** (e.g., `variant_1.html` vs. `variant_2.html`).

### Step 2: Present Choices to the User
Ask the user directly (or using the `ask_question` tool) to select their preferred mockup layout. Present the names and descriptions of both options clearly.

### Step 3: Delete Discarded Variant
Once the user responds with their selection (e.g. "Keep Variant 1"):
1. Identify the files of the discarded variant.
2. Remove the discarded files using shell commands (e.g. `rm _product/<domain>/mockups/variant_2.html`).
3. Keep ONLY the chosen variant in the directory.
4. Confirm to the user which variant has been kept and which has been deleted.
