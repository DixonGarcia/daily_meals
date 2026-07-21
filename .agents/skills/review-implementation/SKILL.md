---
name: review-implementation
description: Guide for performing a thorough security, stability, styling, localization, and performance review on DailyMeals implementation changes.
---

# Reviewing Implementation (`review-implementation`)

Use this skill whenever you need to review implementation code, database migrations, controllers, views, or pull requests in the DailyMeals application. You act as a senior staff-level code reviewer ensuring stability, security, localization compliance, and adherence to the Biteclub design system.

---

## 🔍 Review Framework

### 1. Security Analysis (Critical Priority)
* **Parameters**: Verify that controllers use the modern Rails 8+ `params.expect` rather than old param paradigms to enforce strong parameters.
* **SQL Injection**: Inspect raw SQL queries, AREL queries, and string interpolations in `ActiveRecord` queries.
* **Authentication/Authorization**: Ensure any protected endpoints have proper checks.
* **XSS & Input Sanitization**: Verify HTML escaping in views and proper input sanitization.

### 2. Stability Assessment (Critical Priority)
* **Fail Loudly**: Ensure database mutations (creates, updates, deletes) use bang methods (e.g. `save!`, `update!`, `destroy!`) so exceptions are raised, unless graceful handling is explicitly required.
* **Transactions**: Verify multi-record database mutations (such as importing database items or consolidating shopping lists) are wrapped in `ActiveRecord::Base.transaction` to guarantee database consistency.
* **Nil Guards**: Check for potential `nil` reference errors and ensure proper guards or safe navigation (`&.`) are implemented.
* **Error Handling**: Check rescue blocks to make sure they do not silently swallow critical errors.

### 3. Code Style, Localization & Theme (High Priority)
* **Language Separation**:
  - **Code & Database (Strictly English)**: Schema names, model classes, variables, database tables/columns, service objects, and JSON API payloads must be in **English**.
  - **UI & Database Content (Spanish)**: ERB views, button labels, flash alerts, and select options must be in **Spanish**. Stored database data records must also be in **Spanish**.
* **Internationalization (I18n)**: Strictly check that NO user-facing Spanish text is hardcoded in controllers or views. All alerts, labels, and UI messages must be fetched using Rails locales (`config/locales/es.yml`).
* **YARD Documentation**: Check that classes, modules, and public methods contain structured YARD documentation comments (e.g., `@param`, `@return`, `@raise`).
* **Biteclub Styling**: Check that HTML views conform to the minimalist Biteclub guidelines (White `#ffffff`/`#f8f9fa`, Charcoal `#141414`, Lime Green `#9bc024`, Action Blue `#0094e4`, thin borders `#e9e9e9`, box-shadow `0 4px 20px rgba(0, 0, 0, 0.05)`).
* **Positive Method Naming**: Enforce positive method naming for booleans (e.g. use `active?` instead of `inactive?`, `visible?` instead of `hidden?`).
* **Controller-Model Alignment**: Keep controllers aligned directly with models (e.g. `DishesController` for `Dish`).

### 4. Performance Evaluation (Important)
* **N+1 Queries**: Identify missing eager loading (`includes`, `joins`, `preload`) on associations.
* **Database Indexes**: Verify database migrations add indexes on foreign keys and commonly searched columns.
* **Memoization**: Look for expensive database queries or calculations that could be memoized (e.g. `@list ||= ...`).

---

## 📝 Output Format

When executing a review, structure the output using the following format:

```markdown
## Security Issues
[List any security vulnerabilities with severity and fixes. Include file path on each item]

## Stability Concerns
[List any stability risks with impact assessment and solutions. Include file path on each item]

## Code Quality & Localization
[Review English/Spanish separation, hardcoded UI strings, i18n locales, YARD docs, and Biteclub style guide adherence]

## Performance Optimizations
[List performance improvements with expected impact (e.g., N+1 fixes)]

## Positive Observations
[Acknowledge well-written code, solid test coverage, and good practices]

## Summary
[Overall assessment and must-fix items before merging/deploying]
```
