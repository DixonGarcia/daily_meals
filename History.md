# History

Development log for **DailyMeals**. Entries are newest-first. Each entry covers one logical feature or fix cycle, regardless of how many commits it produced.

---

## [FIX-03] Rails 8 Native params.expect, DRY Refactoring & Deprecation Cleanup — 2026-11-27

A codebase-wide DRY, Clean Code, and Rails 8 conventions audit identified an obsolete Rails 7.2 `params.expect` monkey-patch shadowing Rails 8's native type-safe parameter expectations, duplicated `.env` file readers, repeated view templates and category badge logic, duplicated eager-loading and ingredient normalization code across models/services/controllers, a redundant double `Dish.all` query in `MealPlanHistory#restore_to_calendar!`, a dead `@categories_explicitly_set_empty` reference in `Dish`, missing `@household_setting` initialization in `ApiKeysController#render_validation_error`, and active Rack/Rails 8.1 deprecation warnings.

`config/initializers/parameters_expect.rb` was deleted and callers handling arrays and nested attributes (`Api::V1::MealPlansController#import`, `Api::V1::DishesController#import`, and `DishesController#dish_params`) were updated to native Rails 8 `params.expect` schemas, while `config/application.rb` enabled `config.active_support.to_time_preserves_timezone = :zone` and all controllers and specs standardized on `:unprocessable_content` (eliminating every deprecation warning). Shared logic was extracted into `EnvResolver` (`app/services/env_resolver.rb`, replacing duplicate `.env` parsers in `ApplicationController` and `GeminiClient`), `ApplicationController#current_household_servings`, `ApplicationHelper#dish_category_badge_class`, `Ingredient.normalize_section` / `Ingredient.find_or_create_normalized!`, and `MealPlan.with_dishes_and_ingredients` / `MealPlan.import_schedule!`. View duplication was removed by extracting `app/views/shopping_lists/_section_cards.html.erb` and `app/views/meal_plans/_readonly_meal_slot.html.erb` (with zero inline styles or `.html_safe`), and controllers were cleaned to use `params.expect(:id)`, omit redundant `.all` calls, and avoid unnecessary `set_ingredients` queries on successful `DishesController` writes.

The RSpec suite closed at 150 examples, 0 failures, and 0 deprecation warnings (including new unit coverage in `spec/services/env_resolver_spec.rb`), RuboCop reported 0 offenses across 92 files, and Brakeman (`--except EOLRails`) reported 0 security warnings.

---

## [FEAT-10] Household Diet Profile, Couple & Baby Daily UX, Offline PWA & Dashboard Cleanup — 2026-11-27

Authenticated daily browsing on `/` previously displayed raw `<select>` dropdowns vulnerable to accidental one-handed taps, lacked visibility into tomorrow's meals or proteins needing overnight defrosting, required repeating household diet and Venezuela meal-prep context in every Gemini conversation while dish autocomplete defaulted to two to four servings, carried obsolete dashboard clutter (manual JSON fallback accordion, multi-session chat switcher, and redundant manual history snapshot buttons), silently skipped delete/restore confirmations because Turbo/UJS is not loaded, shipped a default red PWA manifest with a fully commented-out service worker, and returned only dish IDs from `GET /api/v1/meal_plans`.

Database migration `CreateHouseholdSettings` added the singleton `household_settings` table (`servings_multiplier` defaulting to `2` with `1..10` integer validation, and `diet_guidelines` text). `HouseholdSetting` (`HouseholdSetting.current`, read-safe `HouseholdSetting.current_or_default`, and `guidelines_present?`) now supplies the default household servings for `ShoppingListsController#show` and `MealPlansController#index` and is automatically injected into `AiCopilotService#build_system_instruction` and `GeminiClient#suggest_dish_ingredients` (which now targets single-serving catalog portions). `SettingsController` added the `🥗 Dieta y Hogar` tab (`tab=diet`) and `PATCH /settings/household` (`update_household_settings_path`) using `params.expect`. `MealPlan` gained `DEFROST_SECTIONS` (`Carnicería`, `Congelados`), `MealPlan.next_day_for`, and `#defrost_ingredient_names`, which power both the Variant 1 clickable tomorrow radar strip (`tomorrow-radar-strip`) with automatic `❄️ Descongelar hoy` alerts on `/` and the enriched `GET /api/v1/meal_plans` payload (`lunch_dish`, `dinner_dish`, nested ingredients, and `defrost_items`) in `Api::V1::MealPlansController`.

Across the views, `app/views/meal_plans/_day_card.html.erb` switched authenticated Day View to read-first cards with an on-demand `✏️ Editar día` toggle and calendar-aware `from=calendar` dish links handled by `app/views/dishes/show.html.erb`; `app/views/meal_plans/index.html.erb` removed `.legacy-json-details` and `.session-switcher-box` in favor of a single active chat with `🔄 Nuevo chat` and an active diet profile badge; `app/views/settings/show.html.erb` removed redundant manual snapshot buttons; `app/views/layouts/application.html.erb` added native `data-confirm`/`data-turbo-confirm` interception without double prompts, `<meta name="theme-color" content="#ffffff">`, and service worker registration for `/service-worker.js`; and `app/views/pwa/manifest.json.erb` plus `app/views/pwa/service-worker.js` enabled Biteclub PWA branding and network-first offline caching (`dailymeals-v1`) for `/`, `/shopping_list`, and `/dishes`. The RSpec suite closed at 148 examples, 0 failures, RuboCop reported 0 offenses across 91 files, and Brakeman (`--except EOLRails`) reported 0 security warnings.

---

## [FEAT-09] Interactive Shopping List, Calculation Fixes & Venezuelan Market Experience — 2026-11-27

The consolidated shopping list previously lived as a static read-only block buried at the bottom of the main dashboard (`/`), suffered from a calculation bug in `ShoppingListGenerator` where repeated dishes across the week were deduplicated by SQL `WHERE dish_id IN (...)`, lacked household servings scaling, failed to normalize metric units, fractions, or Spanish singular/plural countables, omitted the Venezuelan `Charcutería` stop, mixed dry pantry staples into weekly fresh purchases, and provided no interactive check-off or WhatsApp export. Additionally, `db/seeds.rb` contained unused Breakfast (`Comida 1`), Snack (`Meriendas`), and legacy four-person demo dishes that cluttered the Lunch and Dinner planning flow.

Database migration `AddPantryStapleToIngredients` added the boolean `pantry_staple` column (default `false`, `null: false`) to `ingredients`. `Ingredient::SECTIONS` added `"Charcutería"` and enforced canonical Venezuelan market stop ordering (`Verdulería`, `Carnicería`, `Charcutería`, `Lácteos`, `Panadería`, `Víveres`, `Despensa`, `Congelados`, `Bebidas`, `Limpieza`, `Otros`), with `IngredientsController#ingredient_params` permitting `:pantry_staple`, `app/views/ingredients/_form.html.erb` exposing the pantry staple toggle, and `app/views/ingredients/index.html.erb` displaying the `🏠 Despensa` badge. `ShoppingListGenerator` was rewritten to count every repeated lunch and dinner slot occurrence without SQL deduplication, accept a `servings` multiplier and optional preloaded `meal_plans` (reused by `MealPlansController#index` to eliminate duplicate queries), parse decimals, decimal commas, Unicode/ASCII fractions, and mixed numbers, normalize weight (`g` ↔ `kg`), volume (`ml` ↔ `L`), and Spanish countable singular/plural units, attach per-dish usage metadata, and partition results into weekly fresh items versus pantry staples via `#generate_grouped`. `ShoppingListsController#show` (`GET /shopping_list` with `allow_guest_access`) resolves and persists household servings in a 60-day `shopping_servings` cookie (defaulting to `2`), while `ShoppingListsHelper` supplies section emojis and dish-usage formatting.

The Variant 2 layout (header progress bar, `− / +` servings stepper, segmented `🛒 Frescos | 🏠 Despensa | ✨ Extras` tabs, responsive two-column section card grid with per-stop `📲 Copiar parada` buttons, compact collapsible dish-usage pills when an ingredient spans three or more dishes, `localStorage`-backed weekly check-off and offline extra items scoped by Caracas ISO week, and a sticky bottom WhatsApp copy dock) was implemented across `app/views/shopping_lists/show.html.erb`, `app/views/layouts/application.html.erb` (adding `🛒 Compras` to the navbar), `app/views/meal_plans/index.html.erb` (replacing the static list with a compact summary CTA card and unifying week-view editing into a single transactional `PATCH /meal_plans/update_week` form so updating one day never discards unsaved selections on other days), `config/locales/es.yml`, and `app/assets/stylesheets/application.css`. `db/seeds.rb` was cleaned to seed strictly the 16 Lunch and Dinner diet dishes with concise Spanish names (removing `(Post-entreno)` and verbose phrasing), replacing generic `Vegetales mixtos` with concrete market vegetables (`Brócoli`, `Calabacín`, `Coliflor`, `Espinaca`, `Berenjena`, `Tomate`, `Cebolla`, `Pimentón`), and marking dry staples with `pantry_staple: true`. The RSpec suite closed at 135 examples, 0 failures, RuboCop reported 0 offenses across 87 files, and Brakeman (`--except EOLRails`) reported 0 security warnings.

---

## [FEAT-08] Public Guest Read-Only View, Day/Week Calendar Toggle, Caracas Time Zone & Navbar Cleanup — 2026-11-18

Household members previously had to enter the master password on every visit just to check what was planned for lunch or dinner, the weekly calendar showed all seven days simultaneously without a focused daily view, the server's UTC/Helsinki clock advanced to the next day at 20:00 Venezuela time, and the top-level `🥕 Ingredientes` navigation link occupied navbar space despite being rarely visited directly.

`ApplicationController` introduced the `allow_guest_access` class macro (`skip_before_action :require_authentication!`), enabled on `MealPlansController#index` and `DishesController#index` / `DishesController#show` while keeping all create, update, delete, AI Copilot, ingredient catalog, and settings endpoints protected behind `require_authentication!`. `MealPlansController#index` now guards `@dishes`, `@chat_sessions`, and `resolve_active_chat_session` behind `authenticated?` so guest visits never instantiate `AiChatSession` records, eager-loads `lunch_dish` and `dinner_dish` with `{ dish_ingredients: :ingredient }`, and resolves `@view_mode` (`"day"` by default, `"week"` via `?view=week`), `@today_key` (`Time.zone.today.strftime("%A")`), and `@selected_day`. `config/application.rb` set `config.time_zone = "Caracas"` (`UTC-4`) so daily views and `MealPlanHistory` ISO-week snapshots align with household local time regardless of the Hetzner Helsinki VPS clock.

The Variant 1 layout (segmented `[📅 Por Día | 🗓️ Semana]` toggle paired with a 7-day quick-select chip bar `Lun`–`Dom` and inline dish ingredient pills) was implemented across `app/views/meal_plans/index.html.erb`, `app/views/meal_plans/_day_card.html.erb`, and `app/assets/stylesheets/application.css`. `app/views/layouts/application.html.erb` and `public/robots.txt` added `noindex, nofollow`, replaced `🚪 Salir` with `🔑 Entrar` for guests, and removed `🥕 Ingredientes` from the top navbar, relocating it to an authenticated-only header button inside `app/views/dishes/index.html.erb` while hiding action buttons and the `Acciones` column from unauthenticated visitors in `app/views/dishes/index.html.erb` and `app/views/dishes/show.html.erb`. The lifecycle skills under `.agents/` were also updated for the single-PR workflow on protected `main`. The RSpec suite closed at 122 examples, 0 failures, RuboCop reported 0 offenses across 81 files, and Brakeman reported 0 security warnings.

---

## [FEAT-07] Consolidated Settings (`Configuración`), Meal Plan History & Integrations — 2026-11-16

The top-level `🔑 API Keys` navigation link was replaced with a consolidated **`⚙️ Configuración`** entry (`/settings`) to house both weekly menu archiving and external API token integrations without exceeding four items in the mobile navigation bar on Samsung Galaxy S25+ (`412x915`). Prior to this change, weekly `MealPlan` assignments had no archival history and the rarely visited `API Keys` link lacked explanatory context.

Database migration `CreateMealPlanHistories` created `meal_plan_histories` (`year`, `week_number`, `week_start_date`, `week_end_date`, `plan_snapshot` JSONB, `source`, `notes`, and a unique index on `[:year, :week_number]`). `MealPlanHistory` implements `record_current_week!` for idempotent ISO-week snapshotting (automatically triggered by `MealPlansController#update_day` and `AiCopilotService#apply_session_plan!`) and transactional `restore_to_calendar!` with ID-first and case-insensitive name-fallback resolution that safely skips deleted dishes. `SettingsController#show` (`GET /settings`) renders two tabs (`📚 Historial` by default and `🔌 Integraciones`), `MealPlanHistoriesController` handles `POST /meal_plan_histories/snapshot`, `POST /meal_plan_histories/:id/restore`, and `DELETE /meal_plan_histories/:id`, and `ApiKeysController` plus `app/views/api_keys/_manager.html.erb` preserve `/api_keys` compatibility while redirecting form submissions initiated from `/settings` back to `/settings?tab=integrations`.

During closing, `_product/settings_and_history/implementation.md` and `_product/settings_and_history/mockups/` were removed while keeping `_product/settings_and_history/overview.md`. The RSpec suite closed at 117 examples, 0 failures, and Brakeman reported 0 code security warnings.

---

## [FEAT-06] Copilot Flow Safeguards & Multi-Category Dishes — 2026-11-16

Several usability and data-loss flaws in the Gemini AI Copilot planning flow and dish catalog were resolved. Previously, duplicate day objects in Gemini responses overwrote earlier slots, unchecking `Almuerzo` (`include_lunch`) or unchecking a proposed new dish could blank out existing calendar assignments, stale proposal previews lingered in `AiChatSession` after clicking apply, users had no structured option to generate dish recipes without touching the weekly calendar, and `Dish` records could belong to only a single category (`Lunch`, `Dinner`, or `Both`).

Database migration `AddCategoriesToDishes` added a GIN-indexed `categories` JSONB array to `dishes` and backfilled existing records while preserving `dishes.category` for backward compatibility. `Dish` gained `categories=` normalization, `effective_categories`, `for_category`, and array inclusion validation, exposed through multi-category pill checkboxes (`dish[categories][]`) in `app/views/dishes/_form.html.erb`, flex-wrapped badges in `app/views/dishes/index.html.erb` and `app/views/dishes/show.html.erb`, `DishesController`, and `Api::V1::DishesController`. In `AiCopilotService`, `sanitize_proposed_plan` now merges duplicate weekday entries instead of clobbering slots, respects `days_scope: "none"` (`🚫 Sin calendario`), preserves existing `MealPlan` assignments whenever a slot or new dish is deselected (`apply_selective_meal_plan!`), and resets `proposed_plan` and `proposed_dishes` on `AiChatSession` right after applying. `GeminiClient` and `AiCopilotService` were updated with multi-category schemas (`categories` array) and prompt instructions, while `app/views/meal_plans/index.html.erb`, `AiChatMessagesController`, `AiChatSessionsController#apply`, `config/locales/es.yml`, and `app/assets/stylesheets/application.css` added the synced `🚫 Sin calendario` radio chip, honest preserved-slot indicators (`Se mantiene actual`), and compact S25+ navigation styling.

During closing, `AiCopilotService` also added `Dish` to `ensure_latest_schema_cache!` alongside `AiChatSession` and `AiChatMessage`, and `_product/ai_copilot/implementation.md` and `_product/ai_copilot/mockups/` were removed. The RSpec suite closed at 106 examples, 0 failures, and Brakeman reported 0 code security warnings.

---

## [FIX-02] ActiveRecord Schema Cache Refresh & Gemini Timeout Headroom — 2026-11-15

An `ActiveModel::UnknownAttributeError` (`unknown attribute 'proposed_dishes' for AiChatMessage`) occurred in long-running development server processes that had booted prior to the `FEAT-05` migration (`AddProposedDishesToAiChat`).

`AiCopilotService` was updated to call `ensure_latest_schema_cache!` at the entry points of `converse!` and `apply_session_plan!`, clearing `ActiveRecord::ConnectionAdapters::SchemaCache` and invoking `reset_column_information` on `AiChatSession` and `AiChatMessage` whenever `proposed_dishes` is missing from their cached column list. Additionally, `GeminiClient#post_generate_content` increased `open_timeout` from 5s to 10s and `read_timeout` from 25s to 45s to accommodate detailed nutritional and multi-dish planning prompts. The RSpec suite closed at 100 examples, 0 failures.

---

## [FEAT-05] Hybrid AI Dish & Ingredient Creation — 2026-11-15

A hybrid AI dish and ingredient creation workflow was added across both the weekly calendar chat and the dish catalog form so the owner can dynamically feed new recipes and supermarket ingredients into DailyMeals without leaving their active planning flow.

The migration `AddProposedDishesToAiChat` added the `proposed_dishes` JSONB column to `ai_chat_sessions` and `ai_chat_messages`. `GeminiClient` expanded `RESPONSE_SCHEMA` with `new_dishes` and `lunch_new_dish_name` / `dinner_new_dish_name`, and introduced `DISH_SUGGESTION_SCHEMA` alongside `suggest_dish_ingredients`. `AiCopilotService` removed the legacy offline simulator in favor of live Gemini execution, added `sanitize_proposed_dishes` and `suggest_ingredients_for_dish`, and upgraded `apply_session_plan!` to accept `dish_overrides` from the preview card so only user-checked (`☑️`) dishes and ingredients (with user-edited `suggested_quantity` values) are persisted inside `ActiveRecord::Base.transaction` while matching existing `Ingredient` records case-insensitively. `DishesController` added `POST /dishes/suggest_ingredients` and updated `create` and `update` to support inline brand-new ingredient creation (`ingredient_name` and `supermarket_section`).

The Variant 1 layout (inline ingredient checkboxes and quantity inputs inside the calendar chat preview card paired with an AI autocomplete button in `/dishes/new` and `/dishes/:id/edit`) was selected over Variant 2 (secondary modal editor) and implemented in `app/views/meal_plans/index.html.erb`, `app/views/dishes/_form.html.erb`, and `app/assets/stylesheets/application.css`. End-to-end verification was executed against live Google Gemini on a Samsung Galaxy S25+ viewport (`412x915`), and the RSpec suite closed at 100 examples, 0 failures.

---

## [FIX-01] Gemini Model Aliasing, Fallback & Transactional Chat Persistence — 2026-11-15

A `404 Not Found` error occurred when querying the Google Gemini REST API with `GEMINI_MODEL=gemini-3.1-flash` or legacy `gemini-2.5-flash` on newer API keys, and failed API calls left orphaned user messages in `ai_chat_messages`.

`GeminiClient` was updated to set `DEFAULT_MODEL` to `gemini-3.1-flash-lite`, alias `gemini-3.1-flash` to `gemini-3.1-flash-lite`, strip optional `models/` prefixes, prioritize live `.env` values in development, force UTF-8 encoding on response bodies, and automatically retry across `FALLBACK_MODELS` (`gemini-3.1-flash-lite`, `gemini-flash-latest`, `gemini-flash-lite-latest`, `gemini-3.8-flash`, `gemini-2.5-flash`) when an endpoint returns HTTP `404`, `429`, or `503`. `AiCopilotService#converse!` was refactored so the user `AiChatMessage` and assistant `AiChatMessage` are persisted together inside a single `ActiveRecord::Base.transaction` only after `GeminiClient#generate_plan_response` succeeds. The RSpec suite closed at 93 examples, 0 failures.

---

## [FEAT-04] Persistent Gemini Pseudo-Chat & Guided Menu Loader — 2026-11-15

An interactive, database-persisted Gemini AI Copilot pseudo-chat was added to the DailyMeals dashboard, replacing the manual JSON copy-paste workflow as the primary meal planning assistant. The goal was to let the owner select structured planning parameters, converse naturally in Spanish with Google Gemini, visually preview the proposed weekly menu with real dish names, and load the approved plan into the weekly calendar with a single tap while keeping `GEMINI_API_KEY` isolated on the server.

Two new tables and models were introduced via `CreateAiChatSessionsAndMessages`: `AiChatSession` (`ai_chat_sessions` storing `title`, `parameters`, `proposed_plan`, and `status`) and `AiChatMessage` (`ai_chat_messages` storing `role`, `content`, and `proposed_plan`). `GeminiClient` handles server-side HTTPS calls to `https://generativelanguage.googleapis.com/v1beta/models/:model:generateContent` using `Net::HTTP` and Gemini Structured Outputs (`responseSchema`), while `AiCopilotService` was expanded with `converse!` (which sanitizes proposed dish IDs against `Dish` records and provides a local development planner fallback when `GEMINI_API_KEY` is unset) and `apply_session_plan!` (which atomically updates `MealPlan` records). `AiChatSessionsController` and `AiChatMessagesController` expose `POST /ai_chat_sessions`, `PATCH /ai_chat_sessions/:id/switch`, `POST /ai_chat_sessions/:id/apply`, `DELETE /ai_chat_sessions/:id`, and rate-limited `POST /ai_chat_sessions/:ai_chat_session_id/ai_chat_messages`.

The Variant 1 layout (integrated sidebar chat with quick parameter chips, inline menu preview card, and collapsible manual JSON fallback) was selected over Variant 2 (full-screen modal workspace) and implemented in `app/views/meal_plans/index.html.erb` and `app/assets/stylesheets/application.css`. Mobile ergonomics were verified via headless Chromium emulation on a Samsung Galaxy S25+ viewport (`412x915`), including responsive two-row navigation, quick-jump pills, and stacked mobile dish cards. All Spanish UI strings are managed in `config/locales/es.yml`, and the RSpec suite closed at 91 examples, 0 failures.

---

## [FEAT-03] Single-Owner Access Control — 2026-11-15

Single-owner web authentication was added to protect the DailyMeals interface when deployed under a public custom domain and accessed from mobile or desktop browsers. The goal was to prevent unauthorized internet visitors from viewing or mutating dishes, ingredients, weekly meal plans, or API keys without introducing multi-user database complexity.

Authentication is enforced globally in `ApplicationController` via `before_action :require_authentication!` and `authenticated?`, which compares the SHA-256 digest of `ENV["APP_ACCESS_PASSWORD"]` against `cookies.encrypted[:owner_session]` using `ActiveSupport::SecurityUtils.secure_compare` and fails closed when the environment password is blank. `SessionsController` exposes `GET /session/new`, `POST /session` (protected with Rails 8 `rate_limit` at 5 attempts per 15 minutes and `params.expect(:password)`), and `DELETE /session`, issuing a 60-day HTTP-only encrypted cookie so mobile sessions persist seamlessly while rotating `ENV["APP_ACCESS_PASSWORD"]` immediately revokes all active cookies. `config/boot.rb` includes a zero-dependency `.env` loader paired with `.env.example` so secrets never enter Git.

The Variant 1 layout (minimalist vault card with password visibility toggle and responsive mobile navigation bar) was selected over Variant 2 (split hero banner) and implemented in `app/views/sessions/new.html.erb`, `app/views/layouts/application.html.erb`, and `app/assets/stylesheets/application.css`. All Spanish UI text and flash alerts are managed under `sessions` and `layout.logout` in `config/locales/es.yml`. The RSpec suite closed at 72 examples, 0 failures.

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
