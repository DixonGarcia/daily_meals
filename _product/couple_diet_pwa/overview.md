# Feature Overview: FEAT-10 — Household Diet Profile, Couple & Baby Daily UX, Offline PWA & Dashboard Cleanup

## 1. Business Logic & Domain Context

After **FEAT-09** solved the Venezuelan shopping list and unified weekly planning, several everyday frictions remain for a young couple with a baby using DailyMeals on their VPS (`deals.dixongarcia.com`):

1. **Diet Amnesia in Gemini Copilot**: Every time the couple starts planning with Gemini, they must re-explain their household size, diet guidelines, local Venezuelan food preferences, and meal-prep routine because no persistent household profile exists. Furthermore, dish ingredient autocomplete (`GeminiClient#suggest_dish_ingredients`) still hardcodes `"2 to 4 servings"`, clashing with single-serving diet catalog recipes.
2. **Accidental One-Handed Edits & Nighttime Defrost Friction**: Authenticated users on `/` immediately see `<select>` dropdowns in Day View—easy to bump accidentally while holding a baby—and have no immediate glance at tomorrow's menu or which proteins need to be moved from freezer to fridge tonight (`Carnicería` / `Congelados`).
3. **Dashboard & Settings Visual Noise + Broken Delete Confirmations**: The `/` dashboard still carries the obsolete manual JSON export/import accordion and a ChatGPT-style multi-session switcher; `/settings` shows redundant manual snapshot buttons even though snapshots are automatic; and because Rails Turbo/UJS is not loaded, `data-confirm` / `data-turbo-confirm` prompts do not fire before deleting records.
4. **Unfinished PWA Offline Support**: `manifest.json.erb` still uses Rails' default `"red"` theme/background colors, and `service-worker.js` is completely commented out—leaving the app blank inside supermarkets or *ferias* when mobile reception drops.
5. **Minimalist VPS Automation Readiness**: `GET /api/v1/meal_plans` only returns dish IDs, requiring multiple client calls and manual cross-referencing to send a daily 7:30 AM menu or 8:30 PM defrost alert via Telegram/WhatsApp.

**FEAT-10** resolves all five issues cohesively without over-engineering.

## 2. Concepts & Domain Terminology

- **Household Diet Profile (`HouseholdSetting`)**: Singleton record storing `servings_multiplier` (default `2`, range `1..10`) and `diet_guidelines` (free-text Spanish rules for diet, baby-adaptable cooking, Venezuelan ingredients, and meal prep).
- **Read-First Daily Card**: Default Day View presentation on `/` for both guests and authenticated owners—showing clean dish links and ingredient pills first, with an explicit `✏️ Editar día` toggle revealing the `<select>` form only when requested.
- **Tomorrow & Defrost Radar**: Compact preview of the next calendar day directly beneath the active Day View card, automatically flagging any ingredients from `"Carnicería"` or `"Congelados"` as items to defrost tonight (`❄️ Descongelar`).
- **Streamlined Single-Thread Copilot**: Simplified Gemini sidebar with a single active conversation and a clean `🔄 Nuevo chat` reset button (removing the multi-session dropdown switcher and legacy manual JSON accordion from `/`).
- **Network-First Offline PWA**: Biteclub-branded web app manifest (`#ffffff` / `#f8f9fa`) paired with a lightweight Service Worker caching the most recently visited `/`, `/shopping_list`, and `/dishes` pages plus stylesheet/icons for zero-signal supermarket resilience.

## 3. Core Business Rules

1. **Singleton Household Profile**: `HouseholdSetting.current` always returns a valid persisted or default settings record (`servings_multiplier: 2`, `diet_guidelines: ""`). Updating it via `PATCH /settings/household` requires authentication and validates `servings_multiplier` in `1..10`.
2. **Automatic Gemini Injection**: `AiCopilotService#build_system_instruction` MUST include `HouseholdSetting.current`'s `servings_multiplier` and `diet_guidelines` whenever present. `GeminiClient#suggest_dish_ingredients` MUST request single-serving (`1 porción individual`) quantities consistent with the catalog and respect `diet_guidelines`.
3. **Default Servings Alignment**: When no `shopping_servings` cookie is set, `ShoppingListsController` and `MealPlansController` default to `HouseholdSetting.current.servings_multiplier`.
4. **Read-First Day Card & Defrost Detection**:
   - In Day View (`?view=day`), authenticated users see the clean read-only card by default and can toggle inline editing via `✏️ Editar día`.
   - Tomorrow is computed cyclically from `@selected_day` (`Sunday` → `Monday`).
   - Defrost candidates are all unique ingredient names from tomorrow's `lunch_dish` and `dinner_dish` whose `supermarket_section` is in `["Carnicería", "Congelados"]`, sorted alphabetically.
5. **Reliable Native Confirmation Dialogs**: A lightweight vanilla JS handler in `layouts/application.html.erb` intercepts any form/button with `data-confirm` or `data-turbo-confirm` so accidental taps never delete dishes, ingredients, API keys, or histories without confirmation.
6. **Smart Dish Back Navigation**: Navigating from `/` to `/dishes/:id?from=calendar` renders `"← Volver al Calendario"` linking back to `root_path` instead of `/dishes`.
7. **Backward-Compatible Enriched API**: `GET /api/v1/meal_plans` preserves `id`, `day_of_week`, `lunch_dish_id`, and `dinner_dish_id` while adding nested `lunch_dish`, `dinner_dish` (with `id`, `name`, and `ingredients`), and `defrost_items` so a single VPS cron call powers daily partner notifications.

## 4. User Stories

- **User Story 1 (Persistent Diet Context)**: As a couple following a specific diet in Venezuela, we want to save our diet rules and household size once in Settings so Gemini always respects them without repeating prompts.
- **User Story 2 (One-Handed Safe Reading)**: As a parent holding a baby, I want `/` to open in clean read mode even when logged in so I never bump a dropdown by mistake, while still being able to tap `✏️ Editar día` when needed.
- **User Story 3 (Zero-Effort Defrost Coordination)**: As partners sharing kitchen duties, we want to see tomorrow's menu and an automatic `❄️ Descongelar` badge right beneath today's meals so we never forget to thaw meat the night before.
- **User Story 4 (Offline Supermarket Resilience)**: As a shopper with weak mobile signal inside a supermarket or *feria*, I want DailyMeals installed as a clean Biteclub PWA that opens my last loaded menu and shopping list offline.
- **User Story 5 (Friction-Free Dashboard)**: As a daily user, I want the obsolete JSON tool and chat switcher removed from `/` and delete confirmations fixed across the app so the interface feels calm and trustworthy.

## 5. Mockup Variations Overview

Two interactive Biteclub-themed HTML mockups have been designed under `_product/couple_diet_pwa/mockups/` (each showcasing both `/` Daily View + Tomorrow Radar and `⚙️ Configuración > 🥗 Dieta y Hogar`):

- **Daily View + Tomorrow Radar + Settings Diet Tab**:
  - **Variant 1 (`variant_1_clean_radar.html`) — Tarjeta de Lectura + Franja Compacta "Mañana"**: Clean read-first Today card with `✏️ Editar día` toggle in the header, followed immediately by a slim clickable `"➡️ Mañana (Jueves)"` strip showing lunch/dinner inline plus a soft ice-blue `❄️ Descongelar hoy` pill, paired with the simplified single-thread Gemini sidebar.
  - **Variant 2 (`variant_2_split_cards.html`) — Tarjeta Hoy + Tarjeta Dedicada "Radar de Mañana"**: Clean read-first Today card paired with a distinct compact `"🌙 Radar de Mañana"` card featuring a dedicated blue defrost callout box (`❄️ Bajar a la nevera esta noche: Pechuga de pollo, Pescado`), plus the simplified single-thread Gemini sidebar.

## 6. Selected Variant
- **Selected**: **Variant 1 (`variant_1_clean_radar.html`)** — Tarjeta de Lectura + Franja Compacta "Mañana" (clean read-first Today card with `✏️ Editar día` on-demand toggle, slim clickable `"➡️ Mañana (Jueves)"` strip with inline lunch/dinner summary and ice-blue `❄️ Descongelar hoy` pill, simplified single-thread Gemini sidebar with active diet profile badge, and `⚙️ Configuración > 🥗 Dieta y Hogar` tab).
- **Discarded**: Variant 2 (`variant_2_split_cards.html`) deleted per `choose-mockup`.
