# Feature Overview: FEAT-09 — Interactive Shopping List, Calculation Fixes & Venezuelan Market Experience

## 1. Business Logic & Domain Context

The consolidated shopping list is the core daily habit bridge between planning weekly meals and actually buying groceries. Previously, DailyMeals rendered a read-only ingredient list buried at the bottom of the main dashboard (`/`), suffered from a critical calculation bug that undercounted repeated dishes, lacked unit normalization and household servings scaling, and did not reflect how households actually shop across multiple stops in Venezuela (produce market/*feria*, butcher/*carnicería*, deli/*charcutería*, supermarket/*víveres*).

**FEAT-09** elevates the shopping list into a dedicated, mobile-first, guest-accessible workspace (`/shopping_list`) engineered for one-handed in-store use (even with poor mobile signal), accurate meal-prep quantities, household servings scaling, pantry staple separation, ad-hoc extra items, and one-tap WhatsApp export. It also cleans `db/seeds.rb` to remove unused Breakfast and Snack dishes so the catalog stays focused strictly on Lunch and Dinner planning.

## 2. Concepts & Domain Terminology

- **Shopping List (`/shopping_list`)**: Dedicated, interactive weekly grocery list generated from all active `MealPlan` lunch and dinner assignments. Accessible in read-only/client-interactive mode without login (`allow_guest_access`) so both partners can open it in one tap.
- **Servings Multiplier (`servings`)**: Household headcount multiplier (1x–6x, defaulting to 2x on the shopping page and persisted via cookie) applied on top of per-person recipe quantities so diet recipes stay accurate for kitchen weighing while grocery totals reflect the whole household.
- **Store Stop (`supermarket_section`)**: Physical shopping stop/aisle ordered in practical Venezuelan market sequence (`Verdulería`, `Carnicería`, `Charcutería`, `Lácteos`, `Panadería`, `Víveres`, `Despensa`, `Congelados`, `Bebidas`, `Limpieza`, `Otros`).
- **Pantry Staple (`pantry_staple`)**: Boolean attribute on `Ingredient` marking dry/long-shelf-life staples bought biweekly or monthly (e.g., olive oil, vinegar, rice, lentils, chickpeas). Separated from weekly fresh purchases into a dedicated *"Revisar en despensa"* block so weekly lists stay clean.
- **Quick Extra Item**: Ad-hoc household item not tied to a recipe (e.g., coffee, diapers, drinking water, white cheese), persisted client-side in `localStorage` for offline-friendly shopping and included in WhatsApp exports.
- **Dish Usage Context**: Subtle metadata under each grocery item showing which planned dishes (and how many times) require that ingredient, helping shoppers make informed on-the-spot substitutions when an item is unavailable or overpriced.

## 3. Core Business Rules

1. **Accurate Multiplicity Counting**: If a dish is scheduled multiple times in the weekly `MealPlan` (e.g., 3x meal-prep lunches), its ingredients MUST be summed once per scheduled slot, never deduplicated by `dish_id`.
2. **Servings Scaling**: Every numeric ingredient quantity MUST be multiplied by the active `servings` multiplier (`1` to `10`) before unit normalization and formatting.
3. **Unit Normalization & Parsing**:
   - Supports integers, decimals (`.` and `,`), and common fractions (`1/2`, `1/4`, `3/4`, `½`, `¼`, `¾`, mixed numbers like `1 1/2`).
   - Consolidates weight units (`g`/`gr`/`gramos` ↔ `kg`/`kilos`), auto-promoting sums `>= 1000g` to `kg` (e.g., `1000g` → `1 kg`, `1250g` → `1.25 kg`).
   - Consolidates volume units (`ml`/`cc` ↔ `L`/`litros`), auto-promoting sums `>= 1000ml` to `L`.
   - Consolidates Spanish singular/plural countable units (`unidad`/`unidades`, `lata`/`latas`, `paquete`/`paquetes`, `rebanada`/`rebanadas`, `cucharada`/`cucharadas`, `taza`/`tazas`, `diente`/`dientes`, `manojo`/`manojos`, `medida`/`medidas`).
   - Incompatible units remain cleanly joined with ` + ` without dropping duplicate non-numeric items.
4. **Canonical Venezuelan Section Ordering**: Sections MUST appear in the canonical order defined by `Ingredient::SECTIONS` (including the newly added `"Charcutería"` section), never in arbitrary SQL order.
5. **Pantry Separation**: Ingredients with `pantry_staple: true` are grouped separately from fresh weekly items so users only review them when restocking their pantry.
6. **Guest Accessibility & Offline Resilience**: `/shopping_list` is accessible without login. Check-off state and quick extra items persist in `localStorage` scoped to the current Caracas ISO week (`YYYY-Www`) so checking items off works instantaneously with zero network dependency inside stores.
7. **WhatsApp Plain-Text Export**: One-tap copy generates clean, WhatsApp-formatted Spanish text (`*🥬 Verdulería*`, `- Pechuga de pollo: 540g`) containing ONLY unchecked items (respecting active section filter or full pending list, plus unchecked extras).
8. **Lunch & Dinner Only Seed Catalog**: `db/seeds.rb` removes all Breakfast (`Comida 1`) and Snack (`Meriendas`) dishes, legacy 4-person demo dishes, and unused breakfast/snack-only ingredients, keeping only the structured Lunch & Dinner diet catalog with `pantry_staple` flags properly assigned.

## 4. User Stories

- **User Story 1 (Accurate Meal-Prep Quantities)**: As a meal planner repeating the same lunch 3 times a week for 2 people, I want the shopping list to multiply ingredients by both frequency and servings and convert grams to kilograms, so I buy the exact amount needed.
- **User Story 2 (Multi-Stop Venezuelan Shopping)**: As a shopper visiting the *feria*, *carnicería*, and *charcutería* separately, I want to filter my shopping list by stop and check items off with one hand even when mobile signal drops.
- **User Story 3 (WhatsApp Coordination)**: As a partner coordinating errands, I want to tap one button to copy the remaining unchecked items (either the whole list or a specific stop like *Carnicería*) formatted cleanly for WhatsApp.
- **User Story 4 (Clean Weekly List + Extras)**: As a household shopper, I want dry pantry staples kept out of my weekly fresh list and a quick input to add non-recipe items (coffee, diapers, water) without creating fake dishes.
- **User Story 5 (Focused Lunch/Dinner Catalog)**: As a user who handles breakfasts and snacks separately, I want `db/seeds.rb` cleaned of breakfast and snack dishes so my catalog and AI Copilot focus exclusively on lunches and dinners.

## 5. Mockup Variations Overview

Two interactive Biteclub-themed HTML mockups have been created under `_product/shopping_list/mockups/` using identical realistic Venezuelan diet data and a live switcher bar:

- **Shopping List Workspace (`/shopping_list`)**:
  - **Variant 1 (`variant_1_stop_focus.html`) — Enfoque por Parada + Checklist Compacto**: Sticky top bar with servings pills (`1x–4x`), horizontal store-stop filter chips (`Todas`, `🥬 Verdulería`, `🥩 Carnicería`, `🧀 Charcutería`, `🥫 Víveres`), primary `📲 Copiar para WhatsApp` button, single-column high-contrast checklist with 52px one-handed tap targets and dish-usage subtext, inline quick-add extra bar, and a collapsible `🏠 Revisar en despensa` accordion at the bottom.
  - **Variant 2 (`variant_2_split_dashboard.html`) — Tablero por Pestañas + Copiar por Parada**: Header summary card with visual progress bar and servings stepper (`− 2 +`), segmented category tabs (`🛒 Frescos`, `🏠 Despensa`, `✨ Extras`), responsive multi-card section grid where every section card has its own quick `📲` WhatsApp copy button (ideal for texting only the butcher or produce vendor), and a sticky mobile bottom action dock.
