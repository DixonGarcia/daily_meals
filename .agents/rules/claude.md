# Project Guidelines & Best Practices: DailyMeals (claude.md)

This rule defines the coding style, language conventions, TDD workflows, and environment configurations for the DailyMeals project.

---

## 1. Project Context & Stack
- **Framework**: Ruby on Rails 8.0.x
- **Database**: PostgreSQL (Development & Test)
- **Test Suite**: RSpec (Unit & Request tests)
- **Aesthetic Theme**: Biteclub Modern Minimalist Light Theme (implemented in `app/assets/stylesheets/application.css`)

---

## 2. Language & Naming Conventions
- **Code & Database (Strictly English)**:
  - Database tables, columns, associations, and model names must be in English (e.g., `Dish`, `Ingredient`, `DishIngredient`, `MealPlan`).
  - Controller names, helper methods, service objects, and variables must be in English.
  - **API & JSON Payloads**: All keys returned or received must be in English (e.g., `dish_catalog`, `name`, `category`, `restrictions`, `meal_plan`, `day`, `lunch_dish_id`, `dinner_dish_id`).
- **User-Facing UI & Content (Spanish)**:
  - Frontend views, buttons, forms, labels, flash messages, and select options must be in Spanish.
  - **Database Records (Data)**: The actual data stored (e.g. dish names like `"Carne molida con papas"`, ingredient names like `"Salsa de tomate"`, and supermarket sections like `"Carnicería"`) must be in Spanish.

---

## 3. Workflow & Best Practices

### 3.1. Test-Driven Development (TDD)
Before writing any implementation code:
1. Define the feature specification in a subfolder inside `_product/` (e.g. `_product/feature_name/specification.md`).
2. Write unit specs for models in `spec/models/` and requests in `spec/requests/`.
3. Run the test suite and verify failures.
4. Implement the minimal code required to pass the tests.
5. Refactor and ensure all tests are green.

### 3.2. Clean Specs & Code
- Prefer standard Rails/RSpec reflection matchers for association testing to avoid unnecessary dependency bloat:
  ```ruby
  association = described_class.reflect_on_association(:dish_ingredients)
  expect(association.macro).to eq :has_many
  ```
- Use service objects for complex calculations (e.g. `ShoppingListGenerator` for ingredient aggregation and quantity parsing/consolidation).
- Transactions should be used when importing data to guarantee atomicity. If a record fails validation, roll back the transaction and return false:
  ```ruby
  success = true
  ActiveRecord::Base.transaction do
    # ...
    unless record.save
      success = false
      raise ActiveRecord::Rollback
    end
  end
  success
  ```
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

## 4. Environment & Setup Workarounds

### 4.1. Native Gem Compilation (Linuxbrew issue)
If `bundle install` fails with native extensions compilation due to missing `gmkdir` or `ginstall` commands in `/home/linuxbrew/.linuxbrew/bin/`, run these symlink workarounds:
```bash
ln -sf /usr/bin/mkdir /home/linuxbrew/.linuxbrew/bin/gmkdir
ln -sf /usr/bin/install /home/linuxbrew/.linuxbrew/bin/ginstall
```

### 4.2. Database Configuration
If the system username role (e.g., `dixon`) does not exist in PostgreSQL, create it as a superuser by logging in as the default `postgres` user:
```bash
psql -U postgres -c "CREATE ROLE dixon WITH SUPERUSER LOGIN;"
```

---

## 5. UI & Styling Rules
- **Color Palette**: Strictly follow the Biteclub palette (White body backgrounds `#ffffff`/`#f8f9fa`, charcoal accents `#141414`, lime green `#9bc024`, action blue `#0094e4`).
- **No Heavy Gradients**: Keep the interface clean, flat-minimalist, using elegant shadows (`box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05)`) and thin borders (`#e9e9e9`).
- **Dynamic Rows in Forms**: Use simple vanilla JS clone methods in ERB templates to allow users to add/remove nested items (like dish ingredients) dynamically without adding front-end bloat.

---

## 6. Required Feature Workflow
For any new feature development, the agent must strictly follow and enforce the following sequence of steps:
1. **`build-spec`**: Outline and write the specifications (`overview.md` and `implementation.md`), and design HTML mockup variations inside `_product/<domain>/mockups/` (if the feature has UI components).
2. **`choose-mockup`**: Present the mockup variations to the user, help them choose their preferred option, and document the selection.
3. **`build-feature`**: Implement the backend models, migrations, controllers, locales, HTML/ERB views, and specs in a Test-Driven Development (TDD) loop.
4. **`review-implementation`**: Perform a staff-level code review for security, stability, code style/localization, and performance.
5. **`qa`**: Quality assurance validation (to be defined in detail in a future skill update).

### Workflow Enforcement Guidance:
* If the user attempts to request actions belonging to a later step (for instance, requesting code implementation in `build-feature` before a specification exists or a mockup variant has been chosen), the agent **MUST** remind the user of the expected next step in the workflow.
* If the user, after receiving this reminder, explicitly commands the agent to skip the step, the agent is then permitted to skip the step and proceed as requested.
