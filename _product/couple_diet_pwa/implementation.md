# Feature Technical Implementation: FEAT-10 — Household Diet Profile, Couple & Baby Daily UX, Offline PWA & Dashboard Cleanup

## 1. Data Model & Database Schema Changes

All code, database tables, columns, routes, and API keys remain strictly in **English**. UI labels and stored user data remain in **Spanish**.

### 1.1 Migration: `CreateHouseholdSettings`
- Table: `household_settings`
  - `servings_multiplier`: `integer`, `default: 2`, `null: false`
  - `diet_guidelines`: `text`, `default: ""`, `null: false`
  - `timestamps`

### 1.2 Model: `HouseholdSetting` (`app/models/household_setting.rb`)
- Validations:
  - `validates :servings_multiplier, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }`
- Class method:
  - `HouseholdSetting.current`: returns `first || create!(servings_multiplier: 2, diet_guidelines: "")`.
- Instance helper:
  - `guidelines_present?` (positive predicate returning `diet_guidelines.present?`).

### 1.3 Model Helper: `MealPlan` (`app/models/meal_plan.rb`)
- Constant `DEFROST_SECTIONS = [ "Carnicería", "Congelados" ].freeze`.
- Class method `MealPlan.next_day_for(day_name)` returning the cyclic next weekday (`Sunday` → `Monday`).
- Instance method `defrost_ingredient_names`: returns sorted unique ingredient names from `[ lunch_dish, dinner_dish ].compact` whose `supermarket_section` is in `DEFROST_SECTIONS`.

### 1.4 AI Service Updates
- **`AiCopilotService` (`app/services/ai_copilot_service.rb`)**:
  - Injects `HouseholdSetting.current` into `#build_system_instruction`:
    - Household size (`servings_multiplier` people) and recipe convention (catalog quantities represent 1 single person; shopping list multiplies automatically).
    - `HOUSEHOLD_DIET_GUIDELINES` block when `guidelines_present?`.
  - Passes `diet_guidelines` to `client.suggest_dish_ingredients(...)`.
- **`GeminiClient` (`app/services/gemini_client.rb`)**:
  - Updates `#suggest_dish_ingredients(dish_name:, existing_ingredients:, diet_guidelines: nil)`:
    - Replaces hardcoded `"for 2 to 4 servings"` with `"for 1 single serving (individual diet portion, since the shopping list automatically multiplies by household servings)"`.
    - Appends `HOUSEHOLD_DIET_GUIDELINES` if present.

---

## 2. Controllers & Routing

### 2.1 Routes (`config/routes.rb`)
- Keep `get "settings", to: "settings#show"` and add:
  ```ruby
  patch "settings/household", to: "settings#update_household", as: :update_household_settings
  ```
- Keep legacy `ai_copilots` route intact only if existing `spec/requests/ai_copilots_spec.rb` tests it (removing only the legacy accordion UI from `/`), preserving zero regressions.

### 2.2 `SettingsController` (`app/controllers/settings_controller.rb`)
- Update `VALID_TABS = %w[diet history integrations].freeze` (keep `"history"` as default when `?tab=` is omitted so existing `spec/requests/settings_spec.rb` stays green, and expose `"diet"` as a prominent tab `🥗 Dieta y Hogar`!).
- Load `@household_setting = HouseholdSetting.current` in `#show`.
- Add `#update_household`:
  - Uses `params.expect(household_setting: [ :servings_multiplier, :diet_guidelines ])`.
  - Updates `HouseholdSetting.current` with `update` and redirects to `settings_path(tab: "diet")` with Spanish flash notice (or renders `:show` with `:unprocessable_entity` on validation failure).

### 2.3 `MealPlansController` (`app/controllers/meal_plans_controller.rb`) & `ShoppingListsController`
- Default `@servings` fallback uses `HouseholdSetting.current.servings_multiplier` when no `shopping_servings` cookie is present.
- In `MealPlansController#index`:
  - Compute `@tomorrow_key = MealPlan.next_day_for(@selected_day)`
  - Compute `@tomorrow_plan = @meal_plans[@tomorrow_key]`
  - Compute `@tomorrow_defrost_items = @tomorrow_plan.defrost_ingredient_names`
- In `MealPlansController#index`, only instantiate/load the single active `@active_chat_session` (`AiChatSession.includes(:ai_chat_messages).order(updated_at: :desc).first`) instead of loading all chat sessions for a switcher.

### 2.4 `Api::V1::MealPlansController` (`app/controllers/api/v1/meal_plans_controller.rb`)
- Eager-load `MealPlan.includes(lunch_dish: { dish_ingredients: :ingredient }, dinner_dish: { dish_ingredients: :ingredient }).all`.
- Return JSON array preserving `:id`, `:day_of_week`, `:lunch_dish_id`, `:dinner_dish_id`, plus:
  - `lunch_dish`: `{ id:, name:, ingredients: [ { name:, quantity:, supermarket_section: } ] }` (or `nil`)
  - `dinner_dish`: `{ id:, name:, ingredients: [ { name:, quantity:, supermarket_section: } ] }` (or `nil`)
  - `defrost_items`: `plan.defrost_ingredient_names`

---

## 3. UI, Views, PWA & Locale i18n

### 3.1 Views
- **`app/views/meal_plans/_day_card.html.erb`**:
  - In Day View (`view_mode == "day"`), render the clean read-only card by default for authenticated users too, adding a `✏️ Editar día` toggle button in `.day-header` that reveals the `<form>` (`update_day_meal_plans_path`) inline on tap (and hides it on `Cancelar`).
  - Pass `from: "calendar"` on dish links (`dish_path(plan.lunch_dish, from: "calendar")`).
- **`app/views/meal_plans/index.html.erb`**:
  - Render the winning Tomorrow & Defrost Radar mockup variant directly beneath `.calendar-single-day` when `@view_mode == "day"`.
  - Remove `.legacy-json-details` manual JSON accordion and its dead export/copy JS.
  - Remove `.session-switcher-box` and delete-session button from `#ai-copilot-panel`, replacing with a single clean `🔄 Nuevo chat` button (`POST /ai_chat_sessions`).
- **`app/views/dishes/show.html.erb`**:
  - When `params[:from] == "calendar"`, render Back button linking to `root_path` with `t("dishes.show.back_to_calendar")`.
- **`app/views/settings/show.html.erb`**:
  - Add `🥗 Dieta y Hogar` tab (`tab=diet`) with `servings_multiplier` input (`1..10`) and `diet_guidelines` textarea with helpful Spanish placeholder + save button.
  - Remove redundant manual snapshot buttons (`snapshot_current` / `snapshot_next`) from the `📚 Historial` tab (snapshots are already automatic).
- **`app/views/layouts/application.html.erb`**:
  - Add `<meta name="theme-color" content="#ffffff">`.
  - Register `pwa_service_worker_path` (`navigator.serviceWorker.register(...)`).
  - Add a tiny vanilla JS confirmation listener for `[data-confirm]` and `[data-turbo-confirm]` on submit/click so every delete/restore confirmation works reliably without Turbo/UJS.

### 3.2 PWA Files
- **`app/views/pwa/manifest.json.erb`**:
  - Biteclub palette: `"theme_color": "#ffffff"`, `"background_color": "#f8f9fa"`, `"short_name": "DailyMeals"`, `"description": "Planificador semanal de comidas y lista de compras."`.
- **`app/views/pwa/service-worker.js`**:
  - Minimal, zero-dependency network-first Service Worker (`CACHE_NAME = "dailymeals-v1"`):
    - Caches GET navigation requests (`/`, `/shopping_list`, `/dishes`) and same-origin static assets (CSS, icons) on successful network fetch.
    - Falls back to cached response if offline or network times out (never caches POST/PATCH/DELETE or `/api/` or `/session`).

### 3.3 Locale File (`config/locales/es.yml`)
Add Spanish keys for:
- `meal_plans.index`: `edit_day`, `cancel_edit`, `tomorrow_prefix`, `tomorrow_title`, `defrost_alert`, `defrost_tonight`, `tomorrow_empty`
- `ai_chat_sessions`: `reset_chat` (`"🔄 Nuevo chat"`)
- `dishes.show`: `back_to_calendar` (`"← Volver al Calendario"`)
- `settings.show.tabs.diet`, `settings.diet.*` (title, subtitle, servings_label, servings_hint, guidelines_label, guidelines_placeholder, submit, saved_notice, save_error)

---

## 4. Acceptance Criteria

- **Scenario 1: Household Diet Profile persists and injects into Gemini**
  - **Given** I am authenticated and update `PATCH /settings/household` with `servings_multiplier: 2` and `diet_guidelines: "Dieta 2172 kcal en Venezuela, meal prep"`
  - **When** `AiCopilotService#converse!` constructs the Gemini system instruction
  - **Then** the system instruction includes `"Dieta 2172 kcal en Venezuela, meal prep"` and `servings_multiplier: 2`
  - **And** `ShoppingListsController#show` defaults to `2` servings when no cookie is set.

- **Scenario 2: Read-first Day View and Tomorrow Defrost Radar**
  - **Given** Monday Lunch is `"Pollo con arroz"` (`Pechuga de pollo` in `Carnicería`) and today is Sunday
  - **When** I visit `GET /` (as guest or authenticated)
  - **Then** the Tomorrow Radar shows Monday's lunch and the `❄️ Descongelar` alert listing `"Pechuga de pollo"`
  - **And** authenticated Day View renders the clean read-only view by default alongside the `✏️ Editar día` toggle.

- **Scenario 3: Dashboard cleanup**
  - **Given** I am authenticated and visit `GET /`
  - **Then** the legacy manual JSON accordion (`legacy-json-details`) and multi-session switcher (`session-switcher-box`) are NOT rendered.

- **Scenario 4: Enriched API v1 meal plans**
  - **Given** Monday has a lunch dish with `Pechuga de pollo` (`90g`, `Carnicería`)
  - **When** an API client calls `GET /api/v1/meal_plans` with a valid Bearer token
  - **Then** the Monday JSON object includes `lunch_dish_id`, `lunch_dish.name`, `lunch_dish.ingredients`, and `defrost_items: ["Pechuga de pollo"]`.

- **Scenario 5: Biteclub PWA manifest & Service Worker**
  - **When** requesting `GET /manifest.json` and `GET /service-worker`
  - **Then** `manifest.json` returns `"theme_color": "#ffffff"` and `"background_color": "#f8f9fa"`
  - **And** `service-worker` serves active cache logic (not commented boilerplate).
