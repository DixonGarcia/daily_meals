---
name: build-feature
description: Guide for implementing a DailyMeals feature from an existing specification using TDD, Rails 8, English/Spanish separation, and the Biteclub theme. Creates a feat/ branch from a fresh main.
---

# Implement a Feature (`build-feature`)

Use this skill to build and implement a feature after its specification files have been merged into `main` via `merge-spec`.

---

## Workflow Overview

```
Git Setup  →  Read Spec  →  Migrations  →  Write Specs (Red)  →  Implement (Green)  →  Refactor & Verify
```

---

## Step 1: Git Setup (Run First)

Synchronize with the remote and create a dedicated implementation branch:

```bash
git checkout main
git pull origin main
git checkout -b feat/<FEAT-XX>-<short-slug>
# e.g.: git checkout -b feat/feat-03-shopping-list
# for fixes: git checkout -b fix/fix-01-short-description
```

> The branch name must include the feature ID and a short lowercase hyphenated slug.
> All implementation work (migrations, models, controllers, views, specs) is committed to this branch.
> This branch is merged into `main` by the `close-feature` skill.

---

## Step 2: Read & Analyze Specification Files

1. Read the specification files already present on `main`:
   - `_product/<domain>/overview.md`
   - `_product/<domain>/implementation.md`
2. Also inspect the existing codebase in parallel:
   - `db/schema.rb` — current table structure to avoid duplicate migrations.
   - `config/routes.rb` — existing routes to understand what to add/extend.
   - Related existing models and controllers for conventions to follow.
3. From the spec, identify:
   - Data models and schema migrations (in **English**).
   - Controller actions and routes (in **English**).
   - UI views (ERB) and locale strings (`config/locales/es.yml` in **Spanish**).
   - The selected mockup variant and its styling decisions.
   - Acceptance criteria that will drive the specs.

---

## Step 3: Database Migrations First

Before writing RSpec tests, create and run all necessary migrations. Tests cannot run against a schema that doesn't exist yet.

```bash
bin/rails generate migration CreateXxx ...
bin/rails db:migrate
bin/rails db:migrate RAILS_ENV=test
```

> Verify the migration in `db/schema.rb` before proceeding to specs.

---

## Step 4: Test-Driven Development (TDD) Cycle

### 4.1. Write Unit Specs (Models & Services)
Create tests in `spec/models/<model_name>_spec.rb`:
- Test association macros using `reflect_on_association`.
- Test validations and custom model methods.

### 4.2. Write Integration/Request Specs (Controllers)
Create tests in `spec/requests/<controller_name>_spec.rb`:
- Test HTTP status codes and responses.
- Test parameter handling with `params.expect`.
- Test database state mutations and flash messages.

### 4.3. Run Tests (Red Phase)
Verify that tests fail before writing any implementation code:
```bash
bundle exec rspec spec/models/<model_name>_spec.rb spec/requests/<controller_name>_spec.rb
```
> If tests pass without any implementation code, the specs are not testing the right things. Revisit them.

---

## Step 5: Implementation (Green Phase)

Write the minimal code needed to pass all specs.

### 5.1. Language Separation
- **Code & DB (English)** — Models, attributes, controllers, service objects, helpers, variable names, and JSON payload keys must be in **English**.
- **UI & Data (Spanish)** — ERB templates, buttons, labels, and flash messages must use Spanish text via `config/locales/es.yml`. Stored database content must also be in **Spanish**.

### 5.2. Rails 8 Best Practices
- **Params** — Use `params.expect` (Rails 8+), not `params.require`.
- **Exceptions** — Use bang methods (`save!`, `create!`, `update!`, `destroy!`) to fail loudly, unless graceful failure is explicitly designed.
- **Service Objects** — Extract complex calculations (e.g., ingredient consolidation, list generation) into `app/services/`.
- **Transactions** — Wrap multi-record mutations in `ActiveRecord::Base.transaction`.

### 5.3. Biteclub Theme & UI Rules
- Use CSS tokens defined in `app/assets/stylesheets/application.css`. Do not introduce ad-hoc inline styles.
- Palette: white `#ffffff`/`#f8f9fa`, Charcoal `#141414`, Lime Green `#9bc024`, Action Blue `#0094e4`.
- Minimalist style: thin borders (`#e9e9e9`), soft shadows (`box-shadow: 0 4px 20px rgba(0,0,0,0.05)`).
- Use vanilla JS clone/append methods for dynamic form rows — no JS framework dependencies.

### 5.4. Navigation
If the feature introduces new views, verify that the application layout (`app/views/layouts/application.html.erb`) or shared nav partial includes a link to the new section. Users must be able to reach the feature from the main navigation.

---

## Step 6: Verification & Refactoring

### 6.1. Full Test Suite
Run the complete suite to guarantee no regressions:
```bash
bundle exec rspec
```

### 6.2. Refactor & Document
- Refactor for clarity and remove any shortcuts made during the Green phase.
- Add YARD documentation to all public classes, modules, and non-trivial methods (`@param`, `@return`, `@raise`).
- Verify all user-facing text is localized in `config/locales/es.yml` — no hardcoded Spanish strings in views or controllers.

### 6.3. Commit Green + Refactor Separately
```bash
# After Green phase (all specs pass):
git add .
git commit -m "feat(<domain>): implement FEAT-XX — <short description>"

# After Refactor:
git add .
git commit -m "refactor(<domain>): FEAT-XX — YARD docs, i18n cleanup, code polish"
```
