# DailyMeals Agent Instructions

Welcome! **DailyMeals** is a Ruby on Rails application for planning daily meals and automatically generating consolidated shopping lists.

This file (`.agents/AGENTS.md`) is the entry point for all AI agents working on this codebase. It covers purpose, architecture, guidelines, and mandatory workflows.

> **Language rule**: All code, files, comments, documentation, skill files, and agent instructions must be written in **English**. Spanish is reserved exclusively for `config/locales/es.yml` and the actual UI rendered to the end user.

---

## 📂 Repository Structure

- **`.agents/`** — Agent configuration and instruction sets.
  - **`rules/`** — Coding style and constraint rules.
    - [`claude.md`](file:///home/dixon/Workspace/DailyMeals/daily_meals/.agents/rules/claude.md) — Language conventions, TDD, Rails 8 best practices, Biteclub theme.
  - **`skills/`** — Workflow skills loaded on demand.
    - `build-spec` — Create a `spec/` branch, design mockups, and write the feature spec.
    - `choose-mockup` — Present mockup variants, record the user's choice, delete the discarded variant.
    - `merge-spec` — Merge the approved `spec/` branch into `main`. Runs between `choose-mockup` and `build-feature`.
    - `build-feature` — Create a `feat/` branch and implement via TDD from the merged spec.
    - `review-implementation` — Audit code for security, stability, localization, and performance.
    - `close-feature` — **Mandatory last step**: write `History.md`, merge the `feat/` branch into `main`, delete implementation artifacts.
- **`_product/`** — Feature specifications written before any code is written.
  - Each domain subfolder contains `overview.md` (permanent), `implementation.md` (deleted after `close-feature`), and `mockups/` (permanent).
- **`History.md`** — Project development log at the repository root. One entry per logical feature or fix. Always written by the `close-feature` skill, never edited by hand.
- **`app/`** — Standard Rails layout.
  - `models/` — Models in English (`Dish`, `Ingredient`, `DishIngredient`, `MealPlan`, `ApiKey`).
  - `controllers/` — Rails controllers in English.
  - `views/` — ERB templates rendering Spanish text via i18n.
- **`spec/`** — RSpec test suite.
  - `models/` — Unit tests for model logic and associations.
  - `requests/` — Request / integration specs.

---

## 🛠 Tech Stack

- **Backend**: Ruby on Rails 8.0.x
- **Database**: PostgreSQL
- **Testing**: RSpec
- **Styling**: Vanilla CSS — Biteclub minimalist design system in `app/assets/stylesheets/application.css`.

---

## 🎯 Key Guidelines & Constraints

All agents modifying this codebase **must** follow the rules in [`.agents/rules/claude.md`](file:///home/dixon/Workspace/DailyMeals/daily_meals/.agents/rules/claude.md).

### 1. English Code, Spanish UI

- **Code & Database (strictly English)**: tables, columns, associations, models, controllers, service objects, helpers, variable names, JSON/API payload keys.
- **UI & stored content (Spanish)**: views, buttons, forms, labels, flash messages, select options, and database record values (e.g., dish names, ingredient names) — all via `config/locales/es.yml`.

### 2. Feature Lifecycle (Mandatory Sequence)

Every feature or fix must complete this sequence end-to-end:

1. **Pre-flight** — Read `History.md`. Verify no feature is `[OPEN]`. Determine the next `FEAT-XX` or `FIX-XX` ID.
2. **Spec** (`build-spec` skill) — `git checkout main && git pull`, create `spec/<FEAT-XX>-<slug>` branch, write `overview.md`, `implementation.md`, and `mockups/`.
3. **Design** (`choose-mockup` skill) — Present variants, record choice, delete discarded mockup file.
4. **Merge Spec** (`merge-spec` skill) — Merge `spec/<FEAT-XX>-<slug>` into `main` with `--no-ff`, delete the spec branch.
5. **TDD** (`build-feature` skill) — `git checkout main && git pull`, create `feat/<FEAT-XX>-<slug>` branch, run migrations, write failing specs, implement, refactor.
6. **Review** (`review-implementation` skill) — Audit security, stability, localization, and performance.
7. **Close** (`close-feature` skill — **cannot be skipped**) — Write `History.md` entry, delete `implementation.md` + `mockups/`, merge `feat/<FEAT-XX>-<slug>` into `main` with `--no-ff`, delete the feat branch.

**Branch naming convention**:
- Spec work: `spec/<FEAT-XX>-<short-slug>` (e.g., `spec/feat-03-shopping-list`)
- Implementation: `feat/<FEAT-XX>-<short-slug>` (e.g., `feat/feat-03-shopping-list`)
- Bug fixes: `fix/<FIX-XX>-<short-slug>` (e.g., `fix/fix-01-modal-bind`)

### 3. Biteclub CSS Theme

- Background: white (`#ffffff` / `#f8f9fa`).
- Accent colors: Charcoal (`#141414`), Lime Green (`#9bc024`), Action Blue (`#0094e4`).
- Thin borders (`#e9e9e9`), soft shadows (`box-shadow: 0 4px 20px rgba(0,0,0,0.05)`).
- Use vanilla JS clone/append for dynamic form rows — no JS framework dependencies.

### 4. Code Style & Rails Best Practices

- **Ship to Learn** — Prototype quality is valid. Do not over-engineer prematurely.
- **Fix Root Causes** — Investigate and fix the root problem; avoid patching symptoms.
- **Modern Rails params** — Use `params.expect` (Rails 8+), not `params.require`.
- **Fail Loudly** — Use bang methods (`save!`, `create!`, `update!`, `destroy!`) unless graceful failure is explicitly required.
- **Positive naming** — `active?` not `inactive?`, `visible?` not `hidden?`.
- **Idiomatic Rails** — Follow standard framework conventions.
- **YARD docs** — Document classes, modules, and non-trivial public methods with `@param`, `@return`, `@raise`.
- **Controller-Model alignment** — `DishesController` for `Dish`, `ApiKeysController` for `ApiKey`, etc.
- **Pragmatic extraction** — Keep logic in controllers until the class grows unwieldy, then extract to service objects.
- **I18n** — All user-facing text must go through `config/locales/es.yml`. No hardcoded Spanish strings in views or controllers.

---

## ⚙️ Environment Workarounds

- **PostgreSQL user**: ensure the role `dixon` exists as a superuser.
- **Linuxbrew / native gem compilation**: if bundler fails due to missing `gmkdir` or `ginstall`:
  ```bash
  ln -sf /usr/bin/mkdir /home/linuxbrew/.linuxbrew/bin/gmkdir
  ln -sf /usr/bin/install /home/linuxbrew/.linuxbrew/bin/ginstall
  ```
