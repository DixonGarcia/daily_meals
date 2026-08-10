---
name: build-spec
description: Guide for creating a formal feature specification inside _product/<domain>/ before any implementation begins. Creates a spec/ branch from a fresh main.
---

# Build a Feature Specification (`build-spec`)

Use this skill whenever you need to outline, design, or write a specification for a new feature or domain in DailyMeals before any code is written.

---

## 📂 Output Structure

Every feature specification must live in its own directory `_product/<domain>/` and consist of:

1. **`overview.md`** — Business logic, concepts, rules, and domain explanations. Use [`overview_template.md`](./resources/overview_template.md).
2. **`implementation.md`** — Technical specifications: models, DB schemas, controllers, routes, i18n keys, acceptance criteria. Use [`implementation_template.md`](./resources/implementation_template.md).
3. **`mockups/`** — A folder of static HTML mockups. Required for any feature with a frontend.

---

## 🌿 Git Workflow (Run First)

Before creating any spec file, synchronize with the remote and create a dedicated spec branch:

```bash
git checkout main
git pull origin main
git checkout -b spec/<FEAT-XX>-<short-slug>
# e.g.: git checkout -b spec/feat-03-shopping-list
```

> The branch name must include the feature ID and a short lowercase hyphenated slug describing the domain.
> All spec files (`overview.md`, `implementation.md`, `mockups/`) are committed to this branch.
> This branch will be merged into `main` by the `merge-spec` skill after the mockup is approved.

---

## 🔍 Parallel Research Rules

Before writing the spec, run a research phase to gather context. Follow these rules strictly:

- **No sequential research** — Run operations in parallel (concurrent tasks or a dedicated subagent) rather than blocking sequential reads.
- **Don't re-read context** — Check what files are already in the prompt context. Do NOT re-read files you already have full visibility of.
- **Single research subagent** — If needed, dispatch a single research subagent (`TypeName: "research"`) for bulk codebase exploration. Do not spin up multiple research subagents.

---

## 🎨 Mockup Design Rules

For any UI components, design and save mockups in `_product/<domain>/mockups/`.

- **Always provide 2 variants** — Every UI must have a Variant 1 and a Variant 2 using the same data and context, allowing a side-by-side comparison.
- **Interactive states** — Mockups must demonstrate interactive behavior using vanilla JS and CSS:
  - Toggleable dropdowns, modals, active selections.
  - Form validation states (error vs. success).
  - Empty states vs. loaded states.
  - Dynamic row append/remove.
- **Realistic localized data** — No placeholder text (no Lorem Ipsum). Use realistic Spanish content appropriate for the domain (e.g., real dish names like *"Milanesa de pollo con puré"*, real grocery sections like *"Carnicería"*).
- **Variant switcher** — Include an overlay bar or control at the top of the page allowing the user to toggle between Variant 1 and Variant 2 dynamically in the browser.
- **Biteclub theme** — Both variants must use:
  - Background: white (`#ffffff` / `#f8f9fa`).
  - Accent colors: Charcoal (`#141414`), Lime Green (`#9bc024`), Action Blue (`#0094e4`).
  - Thin borders (`#e9e9e9`), soft shadows (`box-shadow: 0 4px 20px rgba(0,0,0,0.05)`).
  - CSS variables matching the Rails `application.css` configuration.

---

## 🚀 Step-by-Step Workflow

### Step 1: Git Setup
Run the git workflow above to create the `spec/<FEAT-XX>-<slug>` branch before touching any files.

### Step 2: Research Context
1. Check your current context for relevant models, controllers, and rules already loaded.
2. Inspect the existing DB schema (`db/schema.rb`), routes (`config/routes.rb`), and any related models/controllers in parallel.
3. If additional details are needed, spawn **one** research subagent with a clear objective.

### Step 3: Create the Folder Structure
```bash
mkdir -p _product/<domain>/mockups
```

### Step 4: Write `overview.md`
Use [`overview_template.md`](./resources/overview_template.md). Describe business requirements and core constraints.

### Step 5: Write `implementation.md`
Use [`implementation_template.md`](./resources/implementation_template.md). Ensure:
- Data models, columns, controllers, routes, variable names, and API response keys are in **English**.
- Front-end labels, views, buttons, flash alerts, and stored database data are in **Spanish** (via `es.yml`).

### Step 6: Design and Save Mockups
Create two distinct variants (e.g., `variant_1_list.html` and `variant_2_card.html`) under `_product/<domain>/mockups/`. Both must present identical data to allow a direct comparison.

### Step 7: Commit the Spec
```bash
git add _product/<domain>/
git commit -m "spec(<domain>): add FEAT-XX overview, implementation spec, and mockups"
```
