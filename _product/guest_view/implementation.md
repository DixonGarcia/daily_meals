# Technical Implementation Specification — FEAT-08

## 1. Time Zone Configuration (`config/application.rb`)
- Set `config.time_zone = "Caracas"` (`UTC-4`, no DST).
- All `Date.current`, `Time.current`, and `Time.zone.today` calls across `MealPlansController`, `MealPlanHistory`, and `AiChatSessionsController` automatically resolve in `America/Caracas`.

## 2. Authentication & Guest Access (`app/controllers/`)
- `ApplicationController`:
  - Add class macro `self.allow_guest_access(only:)` wrapping `skip_before_action :require_authentication!, only: only`.
- `MealPlansController`:
  - `allow_guest_access only: :index`
  - In `#index`:
    - Eager-load `MealPlan.includes(lunch_dish: { dish_ingredients: :ingredient }, dinner_dish: { dish_ingredients: :ingredient })`.
    - Compute `@view_mode = params[:view] == "week" ? "week" : "day"`.
    - Compute `@today_key = Time.zone.today.strftime("%A")`.
    - Compute `@selected_day = MealPlan::DAYS_OF_WEEK.include?(params[:day]) ? params[:day] : @today_key`.
    - Compute `@shopping_list = ShoppingListGenerator.new.generate`.
    - Guard `@dishes`, `@dishes_by_id`, `@chat_sessions`, and `@active_chat_session` behind `if authenticated?` so guest visits never create `AiChatSession` rows.
  - In `#update_day` (authenticated only):
    - Preserve `view` and `day` params on redirect (`redirect_to root_path(view: params[:view].presence, day: params[:day].presence)`).
- `DishesController`:
  - `allow_guest_access only: %i[index show]`
  - Keep `new`, `create`, `edit`, `update`, `destroy`, and `suggest_ingredients` protected by `require_authentication!`.
- `IngredientsController`:
  - Remains 100% protected by `require_authentication!`.

## 3. Views & Localization (`app/views/`, `config/locales/es.yml`)
- `app/views/layouts/application.html.erb`:
  - Add `<meta name="robots" content="noindex, nofollow">`.
  - Render `📆 Calendario` and `🍽️ Platos` for both guests and authenticated users.
  - Remove `🥕 Ingredientes` from the navbar.
  - When `authenticated?`: render `⚙️ Configuración` and `🚪 Salir`.
  - When unauthenticated: render `🔑 Entrar` (`new_session_path`).
- `app/views/meal_plans/index.html.erb`:
  - Hide `.jump-ai` quick-jump pill and `#ai-copilot-panel` unless `authenticated?`.
  - Add header bar with segmented view toggle (`📅 Día` / `🗓️ Semana`).
  - When `@view_mode == "day"`: render 7 day chips (`Lun`..`Dom`, marking `@today_key` and active `@selected_day`) and the single selected day card (showing read-only dish links + inline ingredient list for guests, or selects + ingredient list for authenticated owner).
  - When `@view_mode == "week"`: render the 7-day calendar grid (read-only dish links for guests, selects + update button for authenticated owner, with a `Hoy` badge on `@today_key`).
- `app/views/dishes/index.html.erb`:
  - Wrap `🥕 Ingredientes` (`ingredients_path`) and `➕ Agregar Nuevo Plato` (`new_dish_path`) buttons in `<% if authenticated? %>`.
  - Wrap `<th>Acciones</th>` and the row action `<td>` in `<% if authenticated? %>`.
- `app/views/dishes/show.html.erb`:
  - Wrap `✏️ Editar Plato` button in `<% if authenticated? %>`.
- `public/robots.txt`:
  - Disallow indexing (`User-agent: *` / `Disallow: /`).

## 4. Acceptance Criteria
- Unauthenticated `GET /` returns HTTP 200, renders today's day card in Caracas time (`UTC-4`), shows the shopping list, hides `#ai-copilot-panel` and `.meal-dish-selector`, and does not create any `AiChatSession`.
- At `2026-11-19 02:00:00 UTC` (`2026-11-18 22:00:00 -0400` in Caracas), `GET /` defaults to Wednesday (`Miércoles`), not Thursday.
- Unauthenticated `GET /dishes` and `GET /dishes/:id` return HTTP 200 and hide all mutation buttons and the Ingredients button.
- Unauthenticated `GET /ingredients`, `GET /dishes/new`, `PATCH /meal_plans/update_day`, and `GET /settings` redirect to `/session/new`.
- Authenticated navbar displays `📆 Calendario`, `🍽️ Platos`, `⚙️ Configuración`, and `🚪 Salir` (no `🥕 Ingredientes` link), while `/dishes` displays the `🥕 Ingredientes` button next to `➕ Agregar Nuevo Plato`.
