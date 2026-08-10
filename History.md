# History

Development log for **DailyMeals**. Entries are newest-first. Each entry covers one logical feature or fix cycle, regardless of how many commits it produced.

---

## [FEAT-02] API Integration & API Key Management — 2026-07-22

Secure programmatic access was added to DailyMeals via a Bearer token API key system. The goal was to allow external clients — AI agents, scripts, or automation tools — to query the dish catalog and weekly meal plans without going through the web UI. The plain-text token is displayed exactly once upon creation and is never stored in cleartext.

The `ApiKey` model was created alongside the `api_keys` table, which stores `name`, `token_digest` (SHA-256 of the actual token), `active`, and `last_used_at`. `ApiKeysController` handles the management UI (index, create, destroy, update) with a pop-up modal that shows the generated token once. The `Api::V1` namespace was introduced: `Api::V1::BaseController` (inheriting from `ActionController::API`) handles `Authorization: Bearer <token>` authentication and stamps `last_used_at` on every valid request. `Api::V1::DishesController` and `Api::V1::MealPlansController` expose `GET /api/v1/dishes`, `GET /api/v1/dishes/:id`, `GET /api/v1/meal_plans`, and `GET /api/v1/meal_plans/:id`, plus `POST /api/v1/dishes/import` and `POST /api/v1/meal_plans/import` for bulk atomic ingestion inside `ActiveRecord::Base.transaction`.

The Variant 2 layout (card grid + modal overlay) was selected over Variant 1 (table + side form). All user-facing labels — including `confirm_revoke`, `masked_key_label`, `understand`, and `cancel` — are managed through `config/locales/es.yml`. The RSpec suite closed at 61 examples, 0 failures.

---

## [FEAT-01] Weekly Meal Planning Core — 2026-07-17

The functional core of DailyMeals was built: a dish catalog with ingredients and a weekly meal planner. The goal was to give users a way to register what to cook each day (lunch and dinner) from their own catalog, as a prerequisite to automatic shopping list generation.

Four tables were created: `dishes` (with `name` and `category`), `ingredients` (with `name` and `supermarket_section`), `dish_ingredients` (join table with `suggested_quantity` and a composite uniqueness constraint on `dish_id` + `ingredient_id`), and `meal_plans` (with a unique `day_of_week`, and `lunch_dish_id` / `dinner_dish_id` as foreign keys to `dishes`). The models `Dish`, `Ingredient`, `DishIngredient`, and `MealPlan` were documented with YARD. `DishesController`, `IngredientsController`, and `MealPlansController` were created with full CRUD actions using `params.expect` and bang methods. ERB views were written in Spanish under the Biteclub visual theme (white `#ffffff`, lime green `#9bc024`, action blue `#0094e4`, border `#e9e9e9`). All UI text and flash messages are managed via `config/locales/es.yml`.

The agent infrastructure was also established in parallel: coding rules in `.agents/rules/claude.md` (English/Spanish separation, TDD, YARD, Rails 8 conventions) and four workflow skills — `build-spec`, `choose-mockup`, `build-feature`, and `review-implementation` — under `.agents/skills/`.

---

## [FEAT-00] Project Bootstrap — 2026-07-17

DailyMeals was initialized as a Ruby on Rails 8.0 application with PostgreSQL, RSpec, and the Biteclub design system foundation. The product roadmap was defined in `_product/` with preliminary specifications for the `meal_planning`, `shopping_list`, `inventory_management`, `dashboard`, and `ai_copilot` modules. The `application.css` stylesheet was configured with color variables and theme tokens, and the PostgreSQL role `dixon` was created as a superuser for the local development environment.

---
