# FEAT-08: Guest Read-Only View, Day/Week Calendar Toggle, Caracas Time Zone & Navbar Cleanup

## 1. Business Context & Problem
Requiring a master password on every visit creates friction when household members simply want to check what is planned for today's lunch or dinner, inspect dish ingredients, or review the shopping list at the supermarket. At the same time, showing all seven days simultaneously on mobile makes finding today's meal unnecessarily dense, the server's UTC/Helsinki clock shifts to the next calendar day at 20:00 Caracas time (UTC-4), and the rarely used `🥕 Ingredientes` top-level navbar link occupies space that is better placed inside the Dish Catalog.

## 2. Core Capabilities & Rules

1. **Public Read-Only Guest Mode**:
   - Unauthenticated visitors can browse:
     - `GET /` and `GET /meal_plans` (Weekly/Daily Calendar + Consolidated Shopping List in read-only mode).
     - `GET /dishes` (Dish Catalog without "+ Agregar Nuevo Plato", "🥕 Ingredientes", or the "Acciones" column).
     - `GET /dishes/:id` (Dish detail & ingredients table without "✏️ Editar Plato").
   - Unauthenticated visitors **cannot**:
     - View or interact with the Gemini AI Copilot chat panel (`#ai-copilot-panel`), the "🤖 Chat Gemini" quick-jump pill, or the manual JSON export/import tool.
     - Trigger `AiChatSession` creation on `GET /`.
     - Mutate any data (`PATCH /meal_plans/update_day`, `DishesController` write/AI endpoints, `IngredientsController`, `SettingsController`, `ApiKeysController`, `MealPlanHistoriesController`, `AiChatSessionsController`, `AiChatMessagesController`, `AiCopilotsController` all require login).

2. **Day / Week Calendar Toggle (Default: Today)**:
   - The main calendar section defaults to **Day View** (`view=day`), displaying the active day in Caracas time (`Time.zone.today`).
   - A segmented toggle switches between **Vista por Día (`📅 Hoy / Día`)** and **Vista Semanal (`🗓️ Semana`)**.
   - In Day View, a 7-chip day bar (`L`, `M`, `M`, `J`, `V`, `S`, `D`) allows one-tap inspection of any day of the week while highlighting today's chip with a lime dot indicator.
   - Each assigned dish in Day View displays its ingredients and suggested quantities inline (for guests) or the dish selector + ingredient summary (for the authenticated owner).
   - In Week View (`view=week`), all seven day cards are displayed with a **"Hoy"** badge on the current day.

3. **Household Time Zone (`Caracas`, UTC-4)**:
   - `config.time_zone = "Caracas"` in `config/application.rb` ensures `Time.zone.today` and `Date.current` always match Venezuela local time (`UTC-4`) regardless of the Hetzner Helsinki VPS system clock.

4. **Navigation & Ingredients Relocation**:
   - **Guest Navbar**: `📆 Calendario` | `🍽️ Platos` | `🔑 Entrar`
   - **Authenticated Navbar**: `📆 Calendario` | `🍽️ Platos` | `⚙️ Configuración` | `🚪 Salir`
   - `🥕 Ingredientes` is removed from the top navbar and placed as a secondary action button (`🥕 Ingredientes`) inside the `/dishes` header exclusively when `authenticated?` is true.

## 3. Selected Variant
- **Variant 1 (`variant_1_day_chips.html`)**: Segmented `[ 📅 Día | 🗓️ Semana ]` toggle paired with the 7-day quick-select chip bar (`Lun`–`Dom`) and inline dish ingredient breakdown on the daily card.
