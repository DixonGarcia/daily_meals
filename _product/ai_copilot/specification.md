# Product Specification: AI Copilot Integration

This feature provides the interface for exchanging planning data with the Gemini AI model (using copy/paste JSON workflows).

## 1. Objectives
- Export the current dish catalog along with user-specified restrictions in the JSON format expected by the AI.
- Import the AI-generated menu plan, updating the weekly database schedules (`MealPlan` records) automatically.

## 2. User Stories

### Story 1: Export Catalog for AI
- **As a** Home Cook
- **I want to** export my dish catalog as a JSON payload
- **So that** I can share it with the AI assistant along with my planning rules (e.g., "Plan Monday to Friday").

### Story 2: Import Plan from AI
- **As a** Home Cook
- **I want to** paste the AI's JSON output back into the app
- **So that** my weekly meal plan calendar is updated instantly without manual entry.

## 3. JSON Interfaces

### 3.1. Export Format (Input to AI)
```json
{
  "dish_catalog": [
    { "id": 1, "name": "Ground beef with potatoes", "category": "Lunch" },
    { "id": 2, "name": "Pasta Bolognese", "category": "Lunch" }
  ],
  "restrictions": "Plan Monday to Friday. Avoid repeating ground beef two days in a row."
}
```

### 3.2. Import Format (Output from AI)
```json
{
  "status": "success",
  "meal_plan": [
    { "day": "Monday", "lunch_dish_id": 1, "dinner_dish_id": 2 },
    { "day": "Tuesday", "lunch_dish_id": null, "dinner_dish_id": 1 }
  ]
}
```

## 4. Acceptance Criteria (Gherkin Scenarios)

### Scenario 1: Exporting the catalog
- **Given** dishes exist in the system
- **When** I request the AI input payload with restrictions "No chicken on Wednesday"
- **Then** the JSON should contain all dishes with their `id`, `name`, and `category`, and the `restrictions` field.

### Scenario 2: Importing a valid plan
- **Given** dishes with IDs 1 and 2 exist
- **When** I import a valid AI plan designating ID 1 for Monday's lunch and ID 2 for Monday's dinner
- **Then** Monday's meal plan should be updated to lunch: ID 1 and dinner: ID 2.
