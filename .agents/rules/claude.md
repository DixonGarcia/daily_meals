# Project Guidelines & Best Practices: DailyMeals (claude.md)

This rule defines the coding style, language conventions, TDD workflows, and environment configurations for the DailyMeals project.

---

## 1. Project Context & Stack
- **Framework**: Ruby on Rails 7.2.x
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
