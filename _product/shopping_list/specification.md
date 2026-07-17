# Product Specification: Dynamic Shopping List

This feature aggregates all ingredients required for the planned meals of the week and groups them by their supermarket section.

## 1. Objectives
- Perform a logical join between all planned dishes (both lunch and dinner) for the week and their ingredients.
- Group the ingredients by their `supermarket_section` (e.g., Butcher, Produce, Pantry).
- Consolidate quantities for duplicate ingredients (e.g., if "Ground beef" is used twice, combine their suggested quantities).

## 2. User Stories

### Story 1: Generate Shopping List
- **As a** Home Cook
- **I want to** view a consolidated shopping list for all my planned meals of the week
- **So that** I know exactly what to buy and can shop efficiently without forgetting anything.

### Story 2: Organized by Section
- **As a** Home Cook
- **I want** the shopping list to be categorized by supermarket aisles (e.g., Butcher, Produce, Pantry)
- **So that** I don't waste time going back and forth in the store.

## 3. Consolidation Logic
For duplicate ingredients, the app should consolidate their quantities:
- If the units match (e.g., "500g" and "250g"), sum them (e.g., "750g").
- If the units differ or are not easily parseable (e.g., "1 can" and "500g"), list them together (e.g., "500g + 1 can").
- Clean up whitespace and format output cleanly.

## 4. Acceptance Criteria (Gherkin Scenarios)

### Scenario 1: Generating and grouping ingredients
- **Given** I have a meal plan with "Pasta Bolognese" (requires "Tomato sauce: 1 can", "Ground beef: 500g")
- **And** "Ground beef with potatoes" (requires "Ground beef: 500g", "Potato: 1 kg")
- **When** I generate the shopping list
- **Then** I should see "Ground beef: 1000g" under "Butcher"
- **And** "Tomato sauce: 1 can" under "Pantry"
- **And** "Potato: 1 kg" under "Produce".
