# DailyMeals

**DailyMeals** is a Ruby on Rails 8 application for planning Monday–Sunday meals, managing a multi-category dish and ingredient catalog, conversing with a Google Gemini AI planning assistant, archiving weekly meal history, and generating consolidated supermarket shopping lists.

> **Language convention**: All code, database schema, comments, and documentation are written in **English**. End-user UI copy (`config/locales/es.yml`) and stored culinary items are in **Spanish**.

---

## Key Capabilities

- **Weekly Meal Calendar & Consolidated Shopping List**: Assign lunch and dinner dishes for Monday through Sunday (`MealPlan`), automatically grouping required ingredients by supermarket section (`ShoppingListGenerator`).
- **Multi-Category Dish & Ingredient Catalog**:
  - `Dish` supports multiple categories (`Lunch`, `Dinner`, `Both` stored in `dishes.categories` JSONB + legacy `category` compatibility) via touch-friendly pill checkboxes.
  - Inline new ingredient creation directly inside `/dishes/new` and `/dishes/:id/edit`.
  - **✨ Autocompletar con IA** (`POST /dishes/suggest_ingredients`) uses Google Gemini structured outputs to populate dish categories and ingredients on demand.
- **Persistent Gemini AI Copilot Pseudo-Chat**:
  - Database-backed chat sessions (`AiChatSession`, `AiChatMessage`) with planning scope chips (`weekdays`, `full_week`, `none` / `🚫 Sin calendario`), meal slot toggles (`include_lunch`, `include_dinner`), and repetition control (`avoid_repetition`).
  - Merges duplicate weekday responses from Gemini, preserves untouched calendar slots during selective updates, clears stale proposals right after applying, and supports on-the-fly creation of brand-new dishes and ingredients with editable quantities.
  - Includes a collapsible manual JSON export/import fallback (`/ai_copilot/export`, `/ai_copilot/import`).
- **Consolidated `⚙️ Configuración` (`/settings`)**:
  - **`📚 Historial`**: Automatically snapshots each ISO week (`MealPlanHistory`) whenever a day is updated manually or a Gemini menu is applied, with one-click manual capture (`POST /meal_plan_histories/snapshot`) and safe transactional calendar restore (`POST /meal_plan_histories/:id/restore`).
  - **`🔌 Integraciones`**: Manage Bearer tokens (`ApiKey`) for external automations without crowding the 4-item mobile navbar.
- **Single-Owner Authentication**: Global web protection via `ENV["APP_ACCESS_PASSWORD"]`, constant-time SHA-256 verification, 60-day encrypted HTTP-only cookies, and Rails 8 `rate_limit` brute-force protection.
- **JSON REST API (`/api/v1`)**:
  - `GET /api/v1/dishes` & `POST /api/v1/dishes/import`
  - `GET /api/v1/meal_plans` & `POST /api/v1/meal_plans/import`
  - Authenticated via `Authorization: Bearer <token>`.

---

## Tech Stack

- **Ruby**: `3.3.5` (`.ruby-version`)
- **Framework**: Ruby on Rails `~> 8.0.0` (Sprockets, Turbo, Stimulus, Importmap)
- **Database**: PostgreSQL (`pg ~> 1.1`)
- **AI Integration**: Google Gemini REST API (`GeminiClient`, `Net::HTTP` with structured JSON schemas and model fallback)
- **Testing & Security**: RSpec (`rspec-rails`), Brakeman
- **UI**: Vanilla CSS (`app/assets/stylesheets/application.css`, Biteclub minimalist design system)

---

## Local Setup & Configuration

### 1. System Prerequisites

- Ruby `3.3.5` and Bundler
- PostgreSQL running locally (ensure your local Postgres user/role has database creation privileges)

### 2. Install Dependencies

```bash
bundle install
```

### 3. Environment Variables (`.env`)

Copy [`.env.example`](.env.example) to `.env` (automatically loaded in local development by `config/boot.rb` and ignored by Git):

```bash
cp .env.example .env
```

Required and optional variables:

| Variable | Description | Default |
| :--- | :--- | :--- |
| `APP_ACCESS_PASSWORD` | Master password required to access the web UI (fails closed if unset) | — |
| `GEMINI_API_KEY` | Google Gemini API key used by the Copilot chat & dish autocomplete | — |
| `GEMINI_MODEL` | Primary Gemini model identifier | `gemini-3.1-flash-lite` |

### 4. Database Setup

```bash
bundle exec rails db:prepare
```

Start the server:

```bash
bin/rails server
```

---

## Running Tests & Security Checks

Run the full RSpec suite:

```bash
bundle exec rspec
```

Run static security analysis:

```bash
bundle exec brakeman -q --no-pager
```

---

## Project Workflows & Architecture Notes

- See [`.agents/AGENTS.md`](.agents/AGENTS.md) and [`.agents/rules/claude.md`](.agents/rules/claude.md) for engineering conventions and the mandatory feature lifecycle (`build-spec` → `choose-mockup` → `merge-spec` → `build-feature` → `review-implementation` → `close-feature`).
- Feature specifications live in [`_product/`](_product/), and completed feature/fix history is recorded chronologically in [`History.md`](History.md).
