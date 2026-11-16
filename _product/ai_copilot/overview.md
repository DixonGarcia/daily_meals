# Feature Overview: Hybrid AI Dish & Ingredient Creation (`FEAT-05`)

## 1. Business Logic & Domain Context
Building upon the Persistent Gemini Pseudo-Chat (`FEAT-04`), **`FEAT-05`** removes the limitation where the assistant could only schedule dishes that already existed in the catalog. In real-world meal planning, the owner frequently thinks of new dishes while planning the weekly calendar or wants to quickly add a new dish in `/dishes/new` without manually typing every ingredient and supermarket aisle. This hybrid workflow enables:
1. **On-the-Fly Dish & Ingredient Creation in the Calendar Chat (`/`)**: When the owner asks Gemini for a dish not yet in the catalog (or asks Gemini to suggest new dishes for the week), Gemini returns both the `meal_plan` schedule and a structured `new_dishes` array containing each new dish's category and ingredients (`name`, `supermarket_section`, `suggested_quantity`). The owner can uncheck (`☑️`) unwanted ingredients or edit quantities directly in the inline preview card before saving and loading the menu in one tap.
2. **Magic Ingredient Autocomplete & Inline New Ingredients in the Dish Form (`/dishes/new` & `/dishes/:id/edit`)**: When creating or editing a dish manually, the owner can tap **"✨ Autocompletar con IA"** next to the dish name to have Gemini populate the category and ingredient rows, and can also register brand-new ingredients inline within the dish form without leaving `/dishes/new`.

## 2. Concepts & Domain Terminology
*   **Proposed New Dish (Plato Nuevo Propuesto)**: A structured recipe (`name`, `category`, `ingredients`) proposed by Gemini inside an `AiChatSession` (`proposed_dishes` JSONB column) that does not yet exist in `dishes`.
*   **Ingredient Override (Ajuste de Ingrediente en Vista Previa)**: User-controlled checkbox (`included`) and editable quantity input (`suggested_quantity`) submitted when applying a session's proposal so only checked ingredients with the user's preferred quantities are persisted.
*   **Case-Insensitive Ingredient Reuse (Reutilización de Ingredientes)**: Automatic matching (`LOWER(name) = LOWER(?)`) against existing `Ingredient` records so existing ingredients are linked without duplication while truly new ingredients are created with their valid `Ingredient::SECTIONS`.
*   **Dish Form AI Autocomplete (Autocompletado de Ingredientes con IA)**: An endpoint (`POST /dishes/suggest_ingredients`) that queries Gemini for a given dish name and populates editable ingredient rows directly inside `/dishes/new` and `/dishes/:id/edit`.

## 3. Core Business Rules
*   **Live Gemini Integration Only**: The legacy local offline simulator is removed; all AI requests execute live against Google Gemini via `GeminiClient`.
*   **Transactional Upsert**: Applying a chat session (`AiCopilotService#apply_session_plan!`) or saving a dish with inline new ingredients (`DishesController`) executes inside `ActiveRecord::Base.transaction`.
*   **Valid Categories & Supermarket Sections**: All proposed dish categories are normalized to `Dish::CATEGORIES` (`Breakfast`, `Lunch`, `Dinner`, `Snack`, `Other`), and all ingredient sections are normalized to `Ingredient::SECTIONS` (defaulting to `'Otros'` if unrecognized).
*   **Selective Ingredient Persistence**: Unchecked ingredients (`included != "1"`) in the preview card are excluded when creating the dish's `DishIngredient` records.

## 4. User Stories
*   **User Story 1**: As the application owner planning my week in `/`, I want to ask Gemini to include a dish that is not in my catalog yet, review its proposed ingredients with checkboxes and editable quantities, and save both the new dish/ingredients and the weekly schedule in one tap.
*   **User Story 2**: As the application owner on `/dishes/new`, I want to type a dish name and tap **"✨ Autocompletar con IA"** so Gemini fills in the category and ingredient rows automatically, including any new ingredients not yet in my database.

## 5. Mockup Variations Overview
*   **Variant 1 (Híbrido Inline: Checkboxes en Vista Previa del Chat + Botón Mágico en Formulario)**:
    *   Displays proposed new dishes and their ingredient checkboxes/quantity inputs directly inside the Calendar Chat preview card, and adds an inline **"✨ Autocompletar con IA"** bar + new-ingredient row support in `/dishes/new`.
*   **Variant 2 (Editor en Modal Separado)**:
    *   Opens a secondary popup modal to edit proposed dishes before returning to the chat.
