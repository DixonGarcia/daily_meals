# Feature Technical Implementation: Multi-Category Dishes & Copilot Flow Safeguards (`FEAT-06`)

## 1. Data Model & Database Schema Changes
- **Migration**: `AddCategoriesToDishes` (`db/migrate/20261116102000_add_categories_to_dishes.rb`)
  - Adds `categories` (`jsonb`, `null: false`, `default: []`) to `dishes` with GIN index.
  - Backfills `categories = jsonb_build_array(category)` for existing rows.
- **Model**: `Dish` (`app/models/dish.rb`)
  - `before_validation :sync_categories_and_primary_category`
  - Validates `categories` is non-empty and all elements are in `Dish::CATEGORIES`.
  - Adds `scope :for_category, ->(cat) { where("categories @> ?", [cat].to_json) }`.

## 2. Services, Controllers & Routing
- **`GeminiClient` (`app/services/gemini_client.rb`)**:
  - Adds `categories` (`ARRAY` of `STRING`) to `RESPONSE_SCHEMA` (`new_dishes`) and `DISH_SUGGESTION_SCHEMA`.
- **`AiCopilotService` (`app/services/ai_copilot_service.rb`)**:
  - `build_system_instruction`: passes `categories: d.categories`; instructs Gemini to emit at most 1 entry per day and `meal_plan: []` when `days_scope == "none"` or both slots are false.
  - `sanitize_proposed_plan`: merges duplicate entries for the same `day`.
  - `converse!`: forces `sanitized_plan = []` when `days_scope == "none"` (or both slots are false), and overwrites `proposed_plan` and `proposed_dishes` cleanly per turn.
  - `apply_session_plan!`: persists multi-category `proposed_dishes`, selectively updates only active & resolved slots (`present?`), and clears `proposed_plan: []`, `proposed_dishes: []` on `session`.
- **`DishesController` & `AiChatSessionsController`**:
  - `DishesController#dish_params`: permits `categories: []`.
  - `AiChatSessionsController#apply`: distinguishes calendar updates vs. dish-only saves for redirect target and flash message.

## 3. UI & Views
- `app/views/dishes/_form.html.erb`, `index.html.erb`, `show.html.erb`: multi-category pill checkboxes (`dish[categories][]` with empty hidden fallback) and flex-wrap tag containers.
- `app/views/meal_plans/index.html.erb`: `🚫 Sin calendario` chip, synced JS toggles, `"Se mantiene actual"` preview display, and `categories[]` inputs inside `dish_overrides`.

## 4. Acceptance Criteria
- **Scenario 1: Multi-category dish creation & backward compatibility**
  - **When** creating a dish with `categories: ["Lunch", "Dinner"]`
  - **Then** `dish.categories` equals `["Lunch", "Dinner"]` and `dish.category` equals `"Lunch"`.
- **Scenario 2: Dinner-only Gemini plan preserves existing lunches and clears preview**
  - **Given** Monday has an existing lunch dish
  - **When** the user sends a dinner-only prompt where Gemini returns duplicate day entries and clicks Apply
  - **Then** Monday keeps its lunch, updates dinner, and clears `session.proposed_plan` & `session.proposed_dishes`.
- **Scenario 3: Consult / create dishes without calendar modification**
  - **When** `days_scope == "none"` and the user saves proposed new dishes
  - **Then** `Dish` and `Ingredient` records are created while `MealPlan` remains untouched.
