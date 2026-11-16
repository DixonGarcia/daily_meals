# Feature Overview: Multi-Category Dishes & Copilot Flow Safeguards (`FEAT-06`)

## 1. Business Logic & Domain Context
Real-world meal planning revealed four UX and data integrity gaps in DailyMeals:
1. Many dishes fit multiple meal times (e.g., `"Carne molida con papas"` or `"Pasta de calabacín"` work for both `Lunch` and `Dinner`). Limiting `Dish` to a single `category` forces artificial choices.
2. When asking Gemini for a dinner-only update (`include_lunch: false, include_dinner: true`), Gemini sometimes returned separate day entries or `nil` lunch values, accidentally wiping out existing lunches when applied.
3. After clicking **"📥 Guardar Platos Nuevos y Cargar Menú"**, the preview card remained visible and accumulated across turns.
4. Planning parameters forced a day-scope radio (`weekdays` or `full_week`), making it impossible to use the chat solely to consult or create new dishes without modifying the weekly calendar.

## 2. Concepts & Domain Terminology
*   **Multi-Category Dish (Plato Multicategoría)**: A `Dish` holding an array of valid meal categories (`categories`, e.g., `["Lunch", "Dinner"]`) while maintaining `category` synchronized to `categories.first` for backward compatibility.
*   **No-Calendar Scope (`days_scope: "none"`)**: A planning mode where the user chats or creates new dishes without modifying any `MealPlan` schedule rows.
*   **Selective Slot Preservation (Preservación Selectiva de Turnos)**: Applying a Gemini proposal merges duplicate day objects by `day` and only overwrites `lunch_dish_id` or `dinner_dish_id` when the slot is both targeted by active parameters and resolved to an existing/created dish ID.
*   **Post-Apply Preview Reset (Limpieza Post-Guardado)**: Applying a session clears `proposed_plan` and `proposed_dishes` on `AiChatSession` so the green preview card disappears cleanly.

## 3. Core Business Rules
*   A `Dish` must have at least one valid category from `Dish::CATEGORIES`.
*   Unchecking both `Almuerzo` and `Cena` in the chat automatically switches `days_scope` to `"none"`; selecting `Lun a Vie` or `Lun a Dom` re-enables `Almuerzo` and `Cena` if both were off.
*   In `proposed-days-list`, untouched slots display `"Se mantiene actual"` (or the current scheduled dish name) instead of `"Ninguno"`.
*   Applying `proposed_dishes` without `proposed_plan` saves dishes/ingredients and redirects back to the chat panel (`#ai-copilot-panel`) without touching `MealPlan`.

## 4. User Stories
*   **User Story 1**: As the application owner, I want to tag a dish as both `Almuerzo` and `Cena` so Gemini and my catalog reflect dishes usable across multiple meal times.
*   **User Story 2**: As the application owner, I want to ask Gemini to update only my dinners without risking my existing lunches, and see the preview clear automatically once saved.
*   **User Story 3**: As the application owner, I want to select `🚫 Sin calendario` (or uncheck all meal slots) to create dishes or chat without changing the weekly calendar.

## 5. Mockup Variations Overview
*   **Variant 1 (Píldoras Multicategoría + Alcance de 3 Opciones Sincronizado)**:
    *   Replaces the single `<select>` with Biteclub pill checkboxes in `/dishes/new`, adds a 3rd `🚫 Sin calendario` chip in the chat, and shows `"Se mantiene actual"` for preserved slots.
*   **Variant 2 (Selector Múltiple Nativo + Toggle Colapsable)**:
    *   Uses a standard `<select multiple>` box and a separate checkbox to disable calendar mode.

## 6. Selected Variant
* **Selected Layout**: **Variant 1 (Píldoras Multicategoría + Alcance de 3 Opciones Sincronizado)**
* **Rationale**: Touch-friendly pill toggles are dramatically faster and clearer on a 412px Samsung Galaxy S25+ screen than multi-select dropdowns.
