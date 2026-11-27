# Feature Technical Implementation: FEAT-09 — Interactive Shopping List, Calculation Fixes & Venezuelan Market Experience

## 1. Data Model & Database Schema Changes

All database objects, column names, models, services, and controller parameters remain strictly in **English**. Stored data values (section names, ingredient names, dish names) and UI strings remain in **Spanish**.

### 1.1 Migration: `AddPantryStapleToIngredients`
- Table: `ingredients`
- New column:
  - `pantry_staple`: `boolean`, `default: false`, `null: false`

### 1.2 Model: `Ingredient` (`app/models/ingredient.rb`)
- Update `SECTIONS` constant to include `"Charcutería"` and enforce practical Venezuelan shopping stop order:
  ```ruby
  SECTIONS = [
    "Verdulería",
    "Carnicería",
    "Charcutería",
    "Lácteos",
    "Panadería",
    "Víveres",
    "Despensa",
    "Congelados",
    "Bebidas",
    "Limpieza",
    "Otros"
  ].freeze
  ```
- Existing validations remain (`name` presence + uniqueness, `supermarket_section` presence + inclusion in `SECTIONS`).
- Positive boolean predicate `pantry_staple?` provided by ActiveRecord.

### 1.3 Service: `ShoppingListGenerator` (`app/services/shopping_list_generator.rb`)
- Signature:
  ```ruby
  class ShoppingListGenerator
    DEFAULT_SERVINGS = 1
    MAX_SERVINGS = 10

    def initialize(servings: DEFAULT_SERVINGS)
    def generate
    def generate_grouped
  end
  ```
- **Multiplicity Fix**:
  - Load `MealPlan.includes(lunch_dish: { dish_ingredients: :ingredient }, dinner_dish: { dish_ingredients: :ingredient }).all`.
  - Iterate over every non-nil `lunch_dish` and `dinner_dish` slot across all days (preserving duplicates).
  - For each slot occurrence, accumulate `{ quantity: dish_ingredient.suggested_quantity, dish_name: dish.name }` keyed by `Ingredient`.
- **Quantity Parsing, Scaling & Normalization**:
  - Normalize Unicode fractions (`½` → `1/2`, `¼` → `1/4`, `¾` → `3/4`, `⅓` → `1/3`, `⅔` → `2/3`) and decimal commas (`1,5` → `1.5`).
  - Parse mixed numbers (`1 1/2 kg`), simple fractions (`1/2 kg`), and decimal/integer numbers (`500g`, `1.5 L`, `2 unidades`).
  - Multiply every parsed numeric quantity by `@servings`.
  - Normalize metric weights (`g`, `gr`, `grs`, `gramo`, `gramos`, `kg`, `kilo`, `kilos`) into grams; format totals `>= 1000` in `kg` (rounded up to 2 decimal places, trimming trailing `.0`, e.g., `1 kg`, `1.25 kg`) and `< 1000` in `g` (e.g., `540g`).
  - Normalize metric volumes (`ml`, `cc`, `l`, `lt`, `lts`, `litro`, `litros`) into milliliters; format totals `>= 1000` in `L` and `< 1000` in `ml`.
  - Normalize Spanish countable units via singular/plural canonical map (`unidad`/`unidades`, `lata`/`latas`, `paquete`/`paquetes`, `rebanada`/`rebanadas`, `cucharada`/`cucharadas`, `taza`/`tazas`, `diente`/`dientes`, `manojo`/`manojos`, `medida`/`medidas`), rendering singular when sum is `1` and plural otherwise.
  - Preserve multiplicity for unparseable non-numeric text (e.g., 2 occurrences of `"al gusto"` render `"al gusto"` or `"al gusto (×2)"` cleanly without silently swallowing counts).
- **Return Formats**:
  - `#generate` returns `Hash{String => Array<Hash>}` ordered strictly by `Ingredient::SECTIONS` index, where each item is:
    ```ruby
    {
      ingredient: ingredient,
      quantity: consolidated_qty,
      dishes: [ { name: dish_name, count: count } ],
      pantry_staple: ingredient.pantry_staple?
    }
    ```
  - `#generate_grouped` partitions `#generate` into:
    ```ruby
    {
      fresh: { "Verdulería" => [...], ... },
      pantry: { "Víveres" => [...], "Despensa" => [...] },
      fresh_count: Integer,
      pantry_count: Integer,
      total_count: Integer
    }
    ```

### 1.4 Seed Data Cleanup (`db/seeds.rb`)
- Remove:
  - All `Comida 1 — Desayunos / Comidas ligeras` dishes (`Breakfast`).
  - All `Meriendas y Pre/Post Entrenamiento` dishes (`Snack`).
  - Legacy 4-person demo dishes (`Carne molida con papas`, `Pasta boloñesa`, `Shawarma de bisteck`).
  - Ingredients no longer referenced by the Lunch & Dinner diet catalog.
- Keep all 16 structured Lunch & Dinner dishes (`Comida 2` + `Comida 3 Post-Entreno`) with accurate single-serving diet weights.
- Mark dry/long-life staples (`Aceite de oliva`, `Arroz integral`, `Arroz blanco`, `Lentejas`, `Garbanzos`, `Quinoa`) with `pantry_staple: true`.

---

## 2. Controllers & Routing

### 2.1 Routes (`config/routes.rb`)
- Add singular resource:
  ```ruby
  resource :shopping_list, only: [ :show ]
  ```
  Exposes `GET /shopping_list` (`shopping_list_path`).

### 2.2 Controller: `ShoppingListsController` (`app/controllers/shopping_lists_controller.rb`)
- Inherits from `ApplicationController`.
- Enables `allow_guest_access only: :show` so both partners can consult and use the shopping list without login.
- Action `show`:
  - Resolves `@servings`:
    - If `params[:servings]` is present and parses to an integer in `1..10`, writes `cookies[:shopping_servings]` (60-day expiry, `same_site: :lax`, `secure: request.ssl?`) and assigns `@servings`.
    - Otherwise falls back to `cookies[:shopping_servings].to_i` (if in `1..10`), defaulting to `2`.
  - Computes `@grouped_list = ShoppingListGenerator.new(servings: @servings).generate_grouped`.
  - Sets `@fresh_sections = @grouped_list[:fresh]`, `@pantry_sections = @grouped_list[:pantry]`, `@fresh_count = @grouped_list[:fresh_count]`, `@pantry_count = @grouped_list[:pantry_count]`, `@total_count = @grouped_list[:total_count]`.
  - Sets `@week_key = Time.zone.today.strftime("%G-W%V")` (Caracas ISO week) for `localStorage` scoping.

### 2.3 Controller Updates
- **`IngredientsController` (`app/controllers/ingredients_controller.rb`)**:
  - Update `ingredient_params`:
    ```ruby
    params.expect(ingredient: [ :name, :supermarket_section, :pantry_staple ])
    ```
- **`MealPlansController` (`app/controllers/meal_plans_controller.rb`)**:
  - Compute `@servings` from `cookies[:shopping_servings]` (default `2`) and `@shopping_summary = ShoppingListGenerator.new(servings: @servings).generate_grouped` to render the lightweight summary CTA card on `/`.

---

## 3. UI, Views & Locale i18n

### 3.1 Views
- **`app/views/layouts/application.html.erb`**:
  - Add `🛒 Compras` (`shopping_list_path`, active when `controller_name == 'shopping_lists'`) to `.nav-links` right after `📆 Calendario`.
  - Guest navbar: `📆 Calendario | 🛒 Compras | 🍽️ Platos | 🔑 Entrar`.
  - Authenticated navbar: `📆 Calendario | 🛒 Compras | 🍽️ Platos | ⚙️ Config | 🚪 Salir`.
- **`app/views/shopping_lists/show.html.erb`**:
  - Implements the winning mockup variant (chosen via `choose-mockup`) with Biteclub styling and vanilla JS:
    - Servings selector (`1`, `2`, `3`, `4` personas) via clean links (`shopping_list_path(servings: n)`).
    - Section filter chips (only rendering sections with items).
    - Interactive check-off persisted in `localStorage` under `dailymeals_checked_#{@week_key}`.
    - Quick extra items persisted in `localStorage` under `dailymeals_extras_#{@week_key}` with add/check/remove controls.
    - Pantry staples separated into `🏠 Revisar en despensa`.
    - `📲 Copiar para WhatsApp` button copying only unchecked items (including unchecked extras and respecting active section filter) using `navigator.clipboard.writeText` with textarea fallback and visual toast confirmation.
    - `↺ Limpiar tachados` reset button.
- **`app/views/meal_plans/index.html.erb`**:
  - Replace the long static `#shopping-list-panel` list with a compact summary CTA card showing pending ingredient count, stop badges, and a button `"🛒 Abrir Lista de Compras"` linking to `shopping_list_path`.
  - Update the mobile quick-jump pill `🛒 Lista de Compras` to link directly to `shopping_list_path`.
- **`app/views/ingredients/_form.html.erb` & `app/views/ingredients/index.html.erb`**:
  - Add `pantry_staple` checkbox with Spanish helper hint in `_form.html.erb`.
  - Display a subtle `🏠 Despensa` badge in `ingredients/index.html.erb` for staple items.

### 3.2 Locale File (`config/locales/es.yml`)
Add/update keys strictly in Spanish:
```yaml
es:
  layout:
    shopping_list: "🛒 Compras"
  ingredients:
    form:
      pantry_staple_label: "🏠 Es básico de despensa"
      pantry_staple_hint: "Se agrupa aparte en «Revisar en despensa» para no saturar tu compra fresca semanal."
    index:
      pantry_badge: "🏠 Despensa"
    sections:
      verduleria: "Verdulería"
      carniceria: "Carnicería"
      charcuteria: "Charcutería"
      lacteos: "Lácteos"
      panaderia: "Panadería"
      viveres: "Víveres"
      despensa: "Despensa"
      congelados: "Congelados"
      bebidas: "Bebidas"
      limpieza: "Limpieza"
      otros: "Otros"
  shopping_lists:
    show:
      title: "🛒 Lista de Compras"
      subtitle: "Plan semanal · %{servings} %{servings_label}"
      servings_label: "Porciones:"
      person_singular: "persona"
      person_plural: "personas"
      filter_all: "Todas"
      copy_whatsapp: "📲 Copiar para WhatsApp"
      copy_section: "Copiar sección"
      copied_toast: "✅ Lista copiada para WhatsApp"
      nothing_to_copy: "No quedan ítems pendientes por copiar."
      clear_checked: "↺ Limpiar tachados"
      pending_count: "%{pending} de %{total} pendientes"
      all_done: "🎉 ¡Todo comprado!"
      pantry_title: "🏠 Revisar en despensa"
      pantry_hint: "Básicos de compra quincenal/mensual usados esta semana. Tacha lo que ya tienes en casa."
      extras_title: "✨ Extras rápidos"
      extras_placeholder: "Agregar extra (ej. pañales, café, agua)..."
      extras_add: "➕ Agregar"
      empty_title: "Tu lista de compras está vacía"
      empty_subtitle: "Planifica almuerzos o cenas en el calendario para generar tus ingredientes automáticamente."
      go_to_calendar: "📆 Ir al Calendario"
  meal_plans:
    index:
      shopping_summary_count: "%{fresh} frescos · %{pantry} de despensa (×%{servings})"
      open_shopping_list: "🛒 Abrir Lista Interactiva"
```

---

## 4. Acceptance Criteria

- **Scenario 1: Repeated dishes multiply ingredient quantities accurately**
  - **Given** "Pollo a la plancha" requires `90g` of `Pechuga de pollo`
  - **And** "Pollo a la plancha" is scheduled on Monday Lunch, Tuesday Lunch, and Wednesday Lunch
  - **When** `ShoppingListGenerator.new(servings: 2).generate` runs
  - **Then** `Pechuga de pollo` appears under `"Carnicería"` with quantity `"540g"` and dish usage `[{ name: "Pollo a la plancha", count: 3 }]`.

- **Scenario 2: Metric unit conversion, fractions, and plural normalization**
  - **Given** planned dishes require `600g` + `1/2 kg` of `Papa`, `700ml` + `0.5 L` of `Leche`, and `1 unidad` + `2 unidades` of `Aguacate`
  - **When** `ShoppingListGenerator.new(servings: 1).generate` runs
  - **Then** `Papa` shows `"1.1 kg"`, `Leche` shows `"1.2 L"`, and `Aguacate` shows `"3 unidades"`.

- **Scenario 3: Canonical Venezuelan section ordering and pantry separation**
  - **Given** planned dishes use `Papa` (`Verdulería`, `pantry_staple: false`), `Jamón de pavo` (`Charcutería`, `pantry_staple: false`), `Pechuga de pollo` (`Carnicería`, `pantry_staple: false`), and `Aceite de oliva` (`Despensa`, `pantry_staple: true`)
  - **When** `ShoppingListGenerator.new.generate_grouped` runs
  - **Then** `:fresh` keys are ordered `["Verdulería", "Carnicería", "Charcutería"]`
  - **And** `Aceite de oliva` appears exclusively under `:pantry["Despensa"]`.

- **Scenario 4: Public guest access and servings persistence on `/shopping_list`**
  - **Given** I am an unauthenticated household member
  - **When** I visit `GET /shopping_list?servings=3`
  - **Then** HTTP status is `200 OK`, quantities are scaled ×3, and the `shopping_servings` cookie is saved as `"3"`.

- **Scenario 5: Ingredient `pantry_staple` CRUD**
  - **Given** I am authenticated
  - **When** I create or update an `Ingredient` with `supermarket_section: "Charcutería"` and `pantry_staple: true`
  - **Then** the record persists both attributes and displays the pantry badge in `/ingredients`.

- **Scenario 6: Lunch & Dinner only seeds**
  - **Given** `db/seeds.rb` is executed on a clean database
  - **Then** zero dishes have `"Breakfast"` or `"Snack"` categories, all 16 Lunch/Dinner diet dishes are created, and dry staples have `pantry_staple: true`.
