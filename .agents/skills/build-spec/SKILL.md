---
name: build-spec
description: Guide for creating a formal feature specification inside _product/<domain>/ before starting implementation.
---

# Building a Feature Specification (`build-spec`)

Use this skill whenever you need to outline, design, or write a specification for a new feature or domain in DailyMeals before any code is written.

---

## 📂 Output Structure
Every feature specification must live in its own directory `_product/<domain>/` and consist of:
1. **`overview.md`**: Business logic, concepts, rules, and domain explanations. Use [overview_template.md](./resources/overview_template.md).
2. **`implementation.md`**: Technical specifications (models, DB schemas, controllers, routes, i18n, acceptance criteria). Use [implementation_template.md](./resources/implementation_template.md).
3. **`mockups/`**: A folder containing static HTML mockups. Required for any feature with a frontend.

---

## 🔍 Parallel Research Rules (Context Gathering)
Before writing the specification, you must perform a research phase to gather context. Adhere strictly to these optimization rules:
* **No Sequential Research**: Run research operations in parallel (using concurrent tasks or a dedicated subagent) rather than performing blocking sequential read/search operations.
* **Don't Re-read Context**: Check what files or outputs are already loaded in the prompt context. **DO NOT** re-read or run search commands for files or documentation that you already have full visibility of to avoid burning token budget.
* **Single Explore Agent**: Dispatch a single research subagent (using `invoke_subagent` with `TypeName: "research"`) for the bulk of the codebase research if needed. Do not spin up multiple research subagents or fragment the exploration task across multiple agents.

---

## 🎨 Mockup Variations & Design Rules
For any user interface components, you must design and provide mockups in `_product/<domain>/mockups/`.
* **Always Provide Variations**: Every UI element must have **2 comparable variants** (Variant 1 and Variant 2) using the *same data* and *same context*. This allows the team/user to compare options side-by-side and choose the best visual/UX fit.
* **Interactive States (Vanilla JS & CSS)**: Mockups must demonstrate interactive behavior. Include functional vanilla JS scripts or CSS triggers to toggle states like:
  - Toggleable dropdowns, active selections, and interactive modals.
  - Form validation states (simulate an error state vs. success state).
  - Empty states vs. loaded states.
  - Adding/removing items dynamically (e.g. appending dynamic form rows).
* **Realistic Localized Data**: Absolutely **no placeholder text (e.g., *Lorem Ipsum*)**. All mockup content must use realistic Spanish datasets appropriate for the domain (e.g., real dishes like *"Milanesa de pollo con puré"*, supermarket sections like *"Carnicería"*, or typical grocery list quantities).
* **Interactive Variant Switcher**: Mockups must include an overlay/bar or control switcher at the top of the interface page (e.g. a simple `<div id="variant-switcher">` with buttons/tabs styled cleanly) allowing the user to toggle between viewing **Variant 1** and **Variant 2** dynamically in the browser.
* **Biteclub Theme Constraints**: Both variants must respect the flat-minimalist Biteclub style guide:
  - Backgrounds: Clean white (`#ffffff` / `#f8f9fa`).
  - Accent colors: Charcoal (`#141414`), Lime Green (`#9bc024`), Action Blue (`#0094e4`).
  - Borders & Shadows: Thin light borders (`#e9e9e9`), elegant soft shadows (`box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05)`).
  - CSS Variables: Define and use custom properties at the top of the mockup stylesheet matching our Rails configuration.

---

## 🚀 Step-by-Step Specification Workflow

### Step 1: Research Context (Optimized)
1. Inspect your current context for relevant files, models, and controller rules.
2. If further details are needed, define a clear objective and spawn **a single research subagent** to fetch the necessary schema definitions or codebase structure.

### Step 2: Create the Folder Structure
```bash
mkdir -p _product/<domain>/mockups
```

### Step 3: Write the Overview Specification
Create `_product/<domain>/overview.md` using the template [overview_template.md](./resources/overview_template.md). Describe the business requirements and core constraints.

### Step 4: Write the Technical Specification
Create `_product/<domain>/implementation.md` using the template [implementation_template.md](./resources/implementation_template.md). Ensure:
- Data models, columns, controllers, routes, variables, and API responses are in **English**.
- Front-end labels, views, buttons, flash alerts, and database record text data are in **Spanish**.

### Step 5: Design and Save Mockups
Create two distinct variants for the frontend elements (e.g., `variant_1_list.html` and `variant_2_card.html`) and save them under `_product/<domain>/mockups/`. Ensure they present the exact same data to permit a direct comparison.
