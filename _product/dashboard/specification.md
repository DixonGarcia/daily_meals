# Product Specification: Interactive Dashboard & UI (Phase 2 & 3)

This specification defines the frontend interface for managing dishes, the weekly calendar, shopping lists, and the AI copilot.

## 1. Objectives
- Provide a main dashboard displaying the weekly calendar (Monday - Sunday) with Lunch and Dinner slots.
- Display a dynamic consolidated shopping list directly on the dashboard, organized by aisle.
- Offer simple view links to manage the Dish and Ingredient inventories.
- Provide a simple text interface for the copy/paste AI Copilot pipeline.

## 2. Views Structure

### 2.1. Dashboard (`/`)
- **Calendar**: A grid of the 7 days of the week, displaying what is planned for Lunch and Dinner.
- **Shopping List**: An accordion or list grouping ingredients by supermarket section.
- **AI Copilot Panel**:
  - A text input for "Planning Restrictions" (e.g., "no beef on Tuesday").
  - A read-only text area displaying the generated JSON to copy.
  - A write-in text area where the user can paste the AI output and click "Import Plan" to run the import.

### 2.2. Dishes CRUD (`/dishes`)
- Simple index, creation, editing, and deletion of dishes.
- Ability to link ingredients with suggested quantities during dish creation/edit.

### 2.3. Ingredients CRUD (`/ingredients`)
- Simple index, creation, editing, and deletion of ingredients.
