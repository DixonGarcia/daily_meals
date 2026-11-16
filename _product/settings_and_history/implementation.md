# Implementation Plan — FEAT-07

## Database
- Migration `CreateMealPlanHistories`: creates `meal_plan_histories` table with `year` (integer, null: false), `week_number` (integer, null: false), `week_start_date` (date, null: false), `week_end_date` (date, null: false), `plan_snapshot` (jsonb, default: `[]`, null: false), `source` (string, default: `"manual"`, null: false), `notes` (string), timestamps, and unique index on `[:year, :week_number]`.

## Models & Services
- `MealPlanHistory`:
  - `validates :year, :week_number, :week_start_date, :week_end_date, :source, presence: true`
  - `validates :week_number, uniqueness: { scope: :year }, inclusion: { in: 1..53 }`
  - `self.record_current_week!(target_date: Date.current, source: "manual")`: computes ISO `cwyear` / `cweek` (`Date.beginning_of_week(:monday)..Date.end_of_week(:sunday)`), serializes Monday–Sunday `MealPlan` slots including `dish_id` and `dish_name` snapshot, and upserts the week's `MealPlanHistory` record.
  - `#restore_to_calendar!`: updates Monday–Sunday `MealPlan` rows inside `ActiveRecord::Base.transaction` using persisted `lunch_dish_id` / `dinner_dish_id`, verifying `Dish.exists?` and falling back to case-insensitive name match or `nil` if deleted, returning `{ restored_slots:, skipped_names: }`.
- Hooks in `MealPlansController#update_day` and `AiCopilotService#apply_session_plan!` auto-record weekly history (`source: "manual"` / `source: "ai_copilot"`).

## Controllers, Views & Routes
- Routes: `get "settings", to: "settings#show"` and `resources :meal_plan_histories, only: %i[destroy]` with collection `post :snapshot` and member `post :restore`.
- `SettingsController#show`: accepts `tab` (`"history"` default or `"integrations"`), loads `@histories` (`order(year: :desc, week_number: :desc)`), `@api_keys`, `@api_key`, `@return_to = "settings"`.
- `MealPlanHistoriesController`: `#snapshot`, `#restore`, `#destroy`.
- `ApiKeysController`: preserve `/api_keys` compatibility while honoring `params[:return_to] == "settings"` to redirect cleanly to `settings_path(tab: "integrations")`.
- Extract `app/views/api_keys/_manager.html.erb` and embed inside `app/views/settings/show.html.erb`.
- Update `app/views/layouts/application.html.erb` replacing `🔑 API Keys` with `⚙️ Configuración` (`/settings`), active for `settings` and `api_keys`.
