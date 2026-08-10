---
name: review-implementation
description: Guide for performing a thorough security, stability, localization, and performance review on DailyMeals implementation changes.
---

# Review an Implementation (`review-implementation`)

Use this skill whenever you need to review implementation code, database migrations, controllers, views, or pull requests in the DailyMeals application. Act as a senior staff-level code reviewer ensuring stability, security, localization compliance, and adherence to the Biteclub design system.

---

## 🔍 Review Framework

### 1. Security Analysis (Critical Priority)

- **Params** — Verify that controllers use `params.expect` (Rails 8+), not the older `params.require` paradigm.
- **SQL Injection** — Inspect raw SQL, AREL, and string interpolations inside `ActiveRecord` queries.
- **Authentication / Authorization** — Confirm that all protected endpoints have proper access checks.
- **XSS & Input Sanitization** — Verify HTML escaping in views and proper input sanitization.

### 2. Stability Assessment (Critical Priority)

- **Fail Loudly** — Database mutations (creates, updates, deletes) must use bang methods (`save!`, `update!`, `destroy!`) so exceptions are raised, unless graceful handling is explicitly required.
- **Transactions** — Multi-record mutations (imports, consolidations) must be wrapped in `ActiveRecord::Base.transaction` to guarantee consistency.
- **Nil Guards** — Check for potential `nil` reference errors; ensure safe navigation (`&.`) or guard clauses are in place.
- **Error Handling** — Verify that rescue blocks do not silently swallow critical errors.

### 3. Code Style, Localization & Theme (High Priority)

- **Language Separation**:
  - **Code & Database (strictly English)** — Schema names, model classes, variables, tables/columns, service objects, and JSON API payloads must be in **English**.
  - **UI & stored content (Spanish)** — ERB views, button labels, flash alerts, and select options must be in **Spanish** via `config/locales/es.yml`. Stored database records must also be in **Spanish**.
- **I18n** — No Spanish text hardcoded in controllers or views. All alerts, labels, and UI messages must use Rails locale helpers.
- **YARD Documentation** — Classes, modules, and public methods must have structured YARD comments (`@param`, `@return`, `@raise`).
- **Biteclub Styling** — HTML views must conform to the minimalist Biteclub guidelines: white `#ffffff`/`#f8f9fa`, Charcoal `#141414`, Lime Green `#9bc024`, Action Blue `#0094e4`, thin borders `#e9e9e9`, shadow `0 4px 20px rgba(0,0,0,0.05)`.
- **Positive Method Naming** — Use `active?` not `inactive?`, `visible?` not `hidden?`.
- **Controller-Model Alignment** — Keep controllers aligned with their models (`DishesController` for `Dish`, etc.).

### 4. Performance Evaluation (Important)

- **N+1 Queries** — Identify missing eager loading (`includes`, `joins`, `preload`) on associations.
- **Database Indexes** — Verify that migrations add indexes on foreign keys and commonly queried columns.
- **Memoization** — Flag expensive queries or calculations that could be memoized (`@list ||= ...`).

---

## 📝 Output Format

Structure the review output as follows:

```markdown
## Security Issues
[List vulnerabilities with severity and fix. Include file path on each item.]

## Stability Concerns
[List risks with impact assessment and solution. Include file path on each item.]

## Code Quality & Localization
[Review English/Spanish separation, hardcoded strings, i18n compliance, YARD docs, Biteclub adherence.]

## Performance Optimizations
[List improvements with expected impact (e.g., N+1 query fixes).]

## Positive Observations
[Acknowledge well-written code, solid test coverage, and good practices.]

## Summary
[Overall assessment and must-fix items before merging or deploying.]
```
