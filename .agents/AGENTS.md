# DailyMeals Agent Instructions

Welcome! This repository, **DailyMeals**, is a Ruby on Rails application designed for planning daily meals and automatically generating consolidated shopping lists. 

This document (`.agents/AGENTS.md`) serves as the entry point for all AI agents working on this codebase. It outlines the project's purpose, architecture, guidelines, and agent instructions.

---

## 📂 Repository Structure for Agents

- **`.agents/`**: Folder dedicated to agent configuration and instruction sets.
  - **`rules/`**: Rules and context instructions.
    - [`claude.md`](file:///home/dixon/Workspace/DailyMeals/daily_meals/.agents/rules/claude.md): Strict styling, language, naming, and TDD guidelines.
  - **`skills/`**: Workflow skills loaded on-demand by agents.
    - `build-spec`: Design mockups and write feature specifications before coding.
    - `choose-mockup`: Present mockup variants and record the user's choice.
    - `build-feature`: Implement a feature via TDD from an existing spec.
    - `review-implementation`: Audit code for security, stability, localization, and performance.
    - `close-feature`: **Mandatory last step** — write `History.md` entry and delete `implementation.md`.
- **`_product/`**: Directory where feature specifications and requirements are written prior to any coding.
  - Every new feature must start with a spec definition inside a subfolder here.
  - Each domain folder contains `overview.md` (permanent), `implementation.md` (deleted after close-feature), and `mockups/` (permanent).
- **`History.md`**: Project development log at the repository root. One entry per logical feature or fix. Never edited manually — always written by the `close-feature` skill.
- **`app/`**: Standard Rails architecture.
  - `models/`: Models in English (e.g., `Dish`, `Ingredient`, `DishIngredient`, `MealPlan`).
  - `controllers/`: Rails controllers in English.
  - `views/`: ERB templates in Spanish (Biteclub Theme).
- **`spec/`**: RSpec testing framework.
  - `models/`: Unit tests for model logic and associations.
  - `requests/`: Request/integration specs.

---

## 🛠 Tech Stack

- **Backend**: Ruby on Rails 8.0.x
- **Database**: PostgreSQL
- **Testing**: RSpec
- **Styling**: Vanilla CSS with custom "Biteclub" minimalist design system in `app/assets/stylesheets/application.css`.

---

## 🎯 Key Guidelines & Constraints

If you are an agent modifying or adding code to this project, you **must** adhere to the following rules defined in [.agents/rules/claude.md](file:///home/dixon/Workspace/DailyMeals/daily_meals/.agents/rules/claude.md):

### 1. English Code, Spanish UI & Data
- **Code & Database (Strictly English)**: Database tables/columns, associations, models, controllers, service objects, helpers, variable names, and JSON/API payload keys must be written in **English**.
- **UI & Database Content (Spanish)**: Views, buttons, forms, labels, flash messages, and select options must be in **Spanish**. The actual stored database records (e.g., dish names, ingredient names) must also be in **Spanish**.

### 2. Feature Lifecycle (Mandatory Sequence)
Every feature or fix must follow this strict sequence end-to-end:

1. **Pre-flight**: Read `History.md` and verify no feature is currently `[OPEN]`. Determine the next `FEAT-XX` or `FIX-XX` ID.
2. **Spec** (`build-spec` skill): Create `_product/<domain>/overview.md`, `implementation.md`, and `mockups/`.
3. **Design** (`choose-mockup` skill): Present variants to the user and record the chosen one.
4. **TDD** (`build-feature` skill): Write failing specs first, then implement minimal code to pass them, then refactor.
5. **Review** (`review-implementation` skill): Audit security, stability, localization, and performance.
6. **Close** (`close-feature` skill — **CANNOT BE SKIPPED**): Write the `History.md` entry (prose, ISO dates, real names) and delete `_product/<domain>/implementation.md`.

### 3. CSS/Styling Theme ("Biteclub")
- Accent colors: White (`#ffffff`/`#f8f9fa`), Charcoal (`#141414`), Lime Green (`#9bc024`), Action Blue (`#0094e4`).
- Flat-minimalist, no heavy gradients, thin borders (`#e9e9e9`), elegant shadows (`box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05)`).
- Use vanilla JS clone/append methods in ERB templates for dynamic form rows (no heavy JS framework dependencies).

### 4. Code Style & Rails Best Practices
- **Ship to Learn**: Prototype quality is valid. Do not over-engineer or polish prematurely; focus on shipping to gather feedback and learn.
- **Fix Root Causes, Not Symptoms**: Avoid implementing quick workarounds for symptoms. Investigate and fix the root of the problem.
- **Modern Rails Parameters**: Use `params.expect` instead of `params.require` for handling controller parameters (following Rails 7.2+ conventions).
- **Fail Loudly (Bang Methods)**: Prefer bang methods (e.g., `save!`, `create!`, `update!`, `destroy!`) so that errors explode and trigger exceptions rather than failing silently, unless handling failures gracefully is a core requirement of the flow.
- **Positive Method Naming**: Use positive names for boolean and query methods (e.g., use `active?` instead of `inactive?`, `visible?` instead of `hidden?`).
- **Idiomatic Rails**: Aim to write pure, clean Rails by following standard framework conventions and design patterns.
- **YARD Documentation**: Document classes, modules, and non-trivial methods using structured YARD comments (e.g., `@param`, `@return`, `@raise`, `@yield`) to keep the codebase self-documenting and clear.
- **Controller-Model Alignment**: Controllers should generally align directly with their corresponding models (e.g., `DishesController` for the `Dish` model).
- **Pragmatic Logic Extraction**: Do not extract logic from controllers prematurely. Keep actions simple and direct; only extract logic to service objects or concerns if the controller action or class starts to grow significantly and becomes difficult to maintain.
- **Internationalization (I18n)**: All user-facing text, alerts, labels, and UI messages must be managed using Rails i18n and locales (e.g., in `config/locales/es.yml` for Spanish UI/messages) instead of being hardcoded in views or controllers.

---

## ⚙️ Environment Workarounds

- **PostgreSQL User**: If you encounter issues connecting, make sure the role `dixon` (superuser) is created.
- **Linuxbrew / Native Gem Compilation**: If bundler fails with native extensions due to missing `gmkdir` or `ginstall` commands under `/home/linuxbrew/.linuxbrew/bin/`, symlink them:
  ```bash
  ln -sf /usr/bin/mkdir /home/linuxbrew/.linuxbrew/bin/gmkdir
  ln -sf /usr/bin/install /home/linuxbrew/.linuxbrew/bin/ginstall
  ```

Please refer to [.agents/rules/claude.md](file:///home/dixon/Workspace/DailyMeals/daily_meals/.agents/rules/claude.md) for detailed code snippets and further context.
