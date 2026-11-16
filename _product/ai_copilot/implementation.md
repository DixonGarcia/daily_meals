# Feature Technical Implementation: Hybrid AI Dish & Ingredient Creation (`FEAT-05`)

## 1. Data Model & Database Schema Changes
- **Migration**: `AddProposedDishesToAiChat` (`db/migrate/20261115224000_add_proposed_dishes_to_ai_chat.rb`)
  - Adds `proposed_dishes` (`jsonb`, `null: false`, `default: []`) to `ai_chat_sessions` and `ai_chat_messages`.

## 2. Services, Controllers & Routing
- **`GeminiClient` (`app/services/gemini_client.rb`)**:
  - Updates `RESPONSE_SCHEMA` to include:
    - `new_dishes`: Array of `{ name, category, ingredients: [{ name, supermarket_section, suggested_quantity }] }`.
    - `meal_plan` items: `{ day, lunch_dish_id, dinner_dish_id, lunch_new_dish_name, dinner_new_dish_name }`.
  - Adds `DISH_SUGGESTION_SCHEMA` and `suggest_dish_ingredients(dish_name:, existing_ingredients:)`.
- **`AiCopilotService` (`app/services/ai_copilot_service.rb`)**:
  - Removes the offline `build_local_development_response` fallback so all requests hit live Gemini.
  - Updates `converse!` to sanitize and persist `new_dishes` in `session.proposed_dishes` and `assistant_message.proposed_dishes`.
  - Updates `apply_session_plan!(session, dish_overrides: nil)` to atomically create/update checked `proposed_dishes` and their checked `ingredients` (with edited quantities), resolve `lunch_new_dish_name` / `dinner_new_dish_name` to the newly created `Dish#id`s, and update `MealPlan`.
  - Adds `suggest_ingredients_for_dish(dish_name)`.
- **`DishesController` (`app/controllers/dishes_controller.rb`)**:
  - Adds `POST /dishes/suggest_ingredients` returning JSON `{ category, ingredients }`.
  - Supports inline new ingredient attributes (`ingredient_name`, `supermarket_section`) inside `dish_ingredients_attributes` during `create` and `update`.

## 3. UI, Views & Locale i18n
- **`app/views/meal_plans/index.html.erb`**:
  - Renders `proposed_dishes` inside the `.proposed-menu-preview` form with ingredient checkboxes (`☑️`) and editable `suggested_quantity` inputs.
- **`app/views/dishes/_form.html.erb`**:
  - Adds the **"✨ Autocompletar con IA"** button next to the dish name input and supports inline new ingredient rows.

## 4. Acceptance Criteria
- **Scenario 1: Creating new dishes and ingredients on the fly from the Calendar Chat**
  - **Given** the user asks Gemini in `/` for a weekly menu that includes a brand-new dish `"Pollo al curry"`
  - **When** Gemini returns `new_dishes` and `meal_plan` and the user unchecks one ingredient, edits a quantity, and submits `POST /ai_chat_sessions/:id/apply`
  - **Then** the new `Dish`, its checked `Ingredient` records, and `DishIngredient` quantities are created atomically and assigned to the `MealPlan` day.
- **Scenario 2: Autocompleting ingredients with AI in `/dishes/new`**
  - **Given** the user enters `"Lasaña boloñesa"` on `/dishes/new` and clicks **"✨ Autocompletar con IA"**
  - **When** `POST /dishes/suggest_ingredients` responds and the user submits the form
  - **Then** any new ingredients and the dish are persisted in PostgreSQL.
