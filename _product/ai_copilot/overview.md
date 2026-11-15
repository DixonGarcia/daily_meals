# Feature Overview: Persistent Gemini Pseudo-Chat & Guided Menu Loader

## 1. Business Logic & Domain Context
Previously, DailyMeals required the owner to manually export a JSON dish catalog, paste it into an external AI window, and paste the resulting JSON back into the dashboard. The Persistent Gemini Pseudo-Chat (`FEAT-04`) replaces that friction with an integrated, database-persisted conversational assistant directly inside the DailyMeals dashboard. The owner can select structured planning parameters (days of the week, lunch/dinner slots, no-repeat rules, and custom instructions), converse naturally in Spanish with Google Gemini, visually preview the proposed weekly menu with real dish names, and load the approved plan into the weekly calendar with a single tap—all while keeping `GEMINI_API_KEY` strictly server-side.

## 2. Concepts & Domain Terminology
*   **AI Chat Session (Sesión de Planificación IA)**: A persisted conversation thread (`AiChatSession`) storing the session title, structured planning parameters (`parameters`), the latest valid menu proposal (`proposed_plan`), and its application status (`active` or `applied`).
*   **AI Chat Message (Mensaje del Copiloto)**: An individual turn (`AiChatMessage`) within a session, authored by either the `user` or the `assistant`, optionally carrying the structured `proposed_plan` snapshot produced on that turn.
*   **Planning Parameters (Parámetros de Planificación)**: Structured constraints sent alongside the dish catalog to Gemini, including target days (`days`), meal slots (`include_lunch`, `include_dinner`), variety rules (`avoid_repetition`), and custom notes.
*   **Proposed Plan Preview (Vista Previa del Menú)**: A human-readable visual summary of the dishes Gemini assigned to each day (resolving `lunch_dish_id` and `dinner_dish_id` against the local `Dish` catalog), paired with a one-click **"📥 Cargar Menú en el Calendario"** button.

## 3. Core Business Rules
*   **Server-Side Secret Isolation**: `ENV["GEMINI_API_KEY"]` is read exclusively on the backend by `GeminiClient` and is never exposed in HTML, JavaScript, or API responses.
*   **Guaranteed Structured Output**: Requests to Gemini use `responseMimeType: "application/json"` and `responseSchema` so every assistant response contains both a conversational `reply` (in Spanish) and a structured `meal_plan` array (`[{ day, lunch_dish_id, dinner_dish_id }]`).
*   **Catalog ID Sanitization**: Any `lunch_dish_id` or `dinner_dish_id` returned by Gemini that does not exist in the local `dishes` table is sanitized to `nil` before persistence, preventing foreign key errors or hallucinated IDs.
*   **Transactional Calendar Application**: Applying a session's `proposed_plan` executes inside an `ActiveRecord::Base.transaction` via `AiCopilotService#import_plan`, atomically updating `MealPlan` records and recalculating the consolidated shopping list.
*   **Rate Limiting**: Message creation (`POST /ai_chat_sessions/:ai_chat_session_id/messages`) is rate-limited using Rails 8 `rate_limit` (15 messages per 5 minutes) to prevent accidental quota exhaustion.
*   **Mobile S25+ Ergonomics**: The pseudo-chat card, parameter chips, message thread, and menu preview card must fit comfortably within a 412px mobile viewport without horizontal scroll.

## 4. User Stories
*   **User Story 1**: As the application owner on my phone or desktop, I want to select planning parameters (e.g., Lunes a Viernes, Almuerzo y Cena, Evitar repetir platos) and ask Gemini in Spanish to propose a weekly menu using my saved dishes.
*   **User Story 2**: As the application owner, I want to iterate in conversation (e.g., *"Cambia el almuerzo del miércoles por algo más ligero"*) and see my conversation history persisted in the database so I can resume from any device.
*   **User Story 3**: As the application owner, I want to see a visual preview of the proposed dishes by name and tap a single button to load the approved menu into my weekly calendar.

## 5. Mockup Variations Overview
Under the `mockups/` folder, two layout variations are provided for comparison:
*   **Variant 1 (Panel de Chat Integrado con Chips de Parámetros y Vista Previa Inline)**:
    *   Replaces the manual JSON sidebar card with an integrated conversational panel featuring quick-toggle parameter pills, a scrollable chat thread, an inline visual card showing the proposed menu with dish names, and a primary **"📥 Cargar Menú en el Calendario"** action button.
*   **Variant 2 (Espacio de Trabajo en Modal Pantalla Completa)**:
    *   Hides the assistant behind a floating trigger button that opens a full-screen multi-column overlay modal.

## 6. Selected Variant
* **Selected Layout**: **Variant 1 (Panel de Chat Integrado con Chips de Parámetros y Vista Previa Inline)**
* **Rationale**: Keeps the conversational assistant, parameter toggles, and proposed weekly menu preview directly visible alongside the weekly calendar and shopping list, avoiding full-screen modal friction on mobile viewports like the Samsung Galaxy S25+ (`412x915`).
