# Product Specification: Weekly Meal Planning

This feature allows users to plan their lunch and dinner for each day of the week.

## 1. Objectives
- Establish a rolling weekly calendar (Monday to Sunday).
- Assign a dish for lunch and/or dinner to any day of the week.
- Leave slots empty (nullable) if no meal is planned.

## 2. User Stories

### Story 1: Plan Daily Meals
- **As a** Home Cook
- **I want to** schedule a dish from my catalog for lunch and/or dinner for any day of the week
- **So that** I know what to cook in advance.

### Story 2: Clear Plan Slot
- **As a** Home Cook
- **I want to** remove a planned meal from a specific slot (lunch or dinner) on a weekday
- **So that** I can adjust my plan dynamically.

## 3. Database Schema (MER)

### `meal_plans`
- `id`: integer, primary key
- `day_of_week`: string, presence: true, uniqueness: true, inclusion in: `['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']`
- `lunch_dish_id`: foreign key -> dishes.id, null: true
- `dinner_dish_id`: foreign key -> dishes.id, null: true

## 4. Acceptance Criteria (Gherkin Scenarios)

### Scenario 1: Planning lunch and dinner for Monday
- **Given** a dish "Ground beef with potatoes" exists
- **And** a dish "Pasta Bolognese" exists
- **When** I set "Ground beef with potatoes" as Monday's lunch
- **And** I set "Pasta Bolognese" as Monday's dinner
- **Then** Monday's meal plan should show "Ground beef with potatoes" for lunch and "Pasta Bolognese" for dinner.

### Scenario 2: Preventing duplicate planning for the same day
- **Given** a meal plan for Monday already exists
- **When** I attempt to create another meal plan for Monday
- **Then** the validation should fail due to uniqueness constraint on `day_of_week`.
