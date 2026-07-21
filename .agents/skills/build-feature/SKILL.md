---
name: build-feature
description: Guide for implementing a feature in DailyMeals from an existing specification using TDD, Rails 8, English/Spanish separation, and Biteclub styling.
---

# Implementing a Feature (`build-feature`)

Use this skill to build and implement a feature after its specification files have been created under `_product/<domain>/`.

---

## Workflow Overview

```
1. Read Spec Files (_product/<domain>/) ➔ 2. Write Specs (spec/) ➔ 3. Red Phase ➔ 4. Minimal Code (Green) ➔ 5. Refactor & Verify
```

---

## Step 1: Read & Analyze Specification Files

1. Read the specification files:
   - `_product/<domain>/overview.md`
   - `_product/<domain>/implementation.md`
2. Identify:
   - Data models and schema migrations (in **English**).
   - Controller actions and routes (in **English**).
   - UI views (`ERB`) and locale strings (`config/locales/es.yml` in **Spanish**).
   - Selected mockup variant and styling.
   - Acceptance criteria.

---

## Step 2: Test-Driven Development (TDD) Cycle

### 2.1. Write Unit Specs (Models & Services)
Create tests in `spec/models/<model_name>_spec.rb`:
- Test association macros using `reflect_on_association`.
- Test validations and custom model methods.

### 2.2. Write Integration/Request Specs (Controllers)
Create tests in `spec/requests/<controller_name>_spec.rb`:
- Test HTTP status codes and responses.
- Test parameter handling with `params.expect`.
- Test database state mutations and flash notices.

### 2.3. Run Tests (Red Phase)
Verify that tests fail prior to writing implementation code:
```bash
bundle exec rspec spec/models/<model_name>_spec.rb spec/requests/<controller_name>_spec.rb
```

---

## Step 3: Implementation (Green Phase)

Write minimal code to pass all specs:

### 3.1. Language Separation
- **Code & DB (English)**: Models, attributes, controllers, service objects, helpers, variable names, and JSON payload keys MUST be in **English**.
- **UI & Data (Spanish)**: ERB templates, buttons, labels, flash messages MUST use Spanish text via `config/locales/es.yml`. Stored DB content MUST be in **Spanish**.

### 3.2. Rails 8 Best Practices
- **Params**: Use `params.expect` (Rails 8+).
- **Exceptions**: Use bang methods (`save!`, `create!`, `update!`, `destroy!`) to fail loudly unless failure handling is explicitly designed.
- **Service Objects**: Extract complex calculations (e.g. ingredient consolidation) into `app/services/`.
- **Transactions**: Wrap multi-record mutations in `ActiveRecord::Base.transaction`.

### 3.3. Biteclub Theme & UI Rules
- Use CSS tokens defined in `app/assets/stylesheets/application.css`.
- Palette: White `#ffffff`/`#f8f9fa`, Charcoal `#141414`, Lime Green `#9bc024`, Action Blue `#0094e4`.
- Minimalist style with thin borders (`#e9e9e9`) and soft shadows (`box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05)`).
- Use vanilla JS clone methods for dynamic form rows.

---

## Step 4: Verification & Refactoring

1. Run the full test suite to guarantee no regressions:
   ```bash
   bundle exec rspec
   ```
2. Refactor code for cleanliness and YARD documentation.
3. Verify all user-facing text is properly localized in `config/locales/es.yml`.
