# FEAT-07: Consolidated Settings (`Configuración`), Weekly Meal History & Integrations

## Business Context & Problem
DailyMeals previously exposed a dedicated top-level `🔑 API Keys` navigation item for token management, which was rarely visited day-to-day yet occupied valuable space in the 4-item mobile navbar. At the same time, the weekly meal calendar (`MealPlan`) overwrote previous weeks' menus with no historical archive or restore capability. Adding a 5th navbar item would break mobile one-line responsiveness on Samsung Galaxy S25+ (`412x915`).

## Solution Overview
Replace `🔑 API Keys` in the navbar with **`⚙️ Configuración`** (`/settings`), keeping the navigation bar at **4 items total**. Inside `/settings`, organize secondary configuration into two clean tabs:
1. **`📚 Historial` (default tab)** — Weekly snapshots of `MealPlan` assignments (`MealPlanHistory`), automatically captured whenever a day is updated (`MealPlansController#update_day`) or a Copilot plan is applied (`AiCopilotService#apply_session_plan!`), plus one-click manual snapshots ("Esta semana" / "Próxima semana"), collapsible day summaries, safely guarded restore to active calendar, and deletion.
2. **`🔌 Integraciones`** — The API Keys management panel (`ApiKey`) paired with clear explanatory copy describing how REST API integrations (e.g., Siri Shortcuts, Home Assistant, external scripts) use bearer tokens.
