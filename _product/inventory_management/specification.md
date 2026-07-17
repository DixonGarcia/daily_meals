# Product Specification: Dish & Ingredient Inventory Management

This feature enables users to manage their kitchen's culinary inventory: dishes, ingredients, and the recipes connecting them.

## 1. Objectives
- Allow users to perform CRUD operations on **Dishes**.
- Allow users to perform CRUD operations on **Ingredients**.
- Link ingredients to dishes with a suggested quantity (DishIngredient) to form a basic recipe database.

## 2. User Stories

### Story 1: Manage Ingredients
- **As a** Home Cook
- **I want to** add, view, update, and delete ingredients with their supermarket section
- **So that** I can keep my grocery list organized by aisle.

### Story 2: Manage Dishes
- **As a** Home Cook
- **I want to** add, view, update, and delete dishes with their meal category (e.g., Breakfast, Lunch, Dinner, Snack, Other)
- **So that** I can build my daily and weekly menu plans.

### Story 3: Recipe Association
- **As a** Home Cook
- **I want to** associate multiple ingredients and their suggested quantities with a dish
- **So that** the app can automatically calculate the shopping list for my planned meals.

## 3. Database Schema (MER)

### `dishes`
- `id`: integer, primary key
- `name`: string, presence: true, uniqueness: true (e.g., "Ground beef with potatoes")
- `category`: string, presence: true, inclusion: ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Other']

### `ingredients`
- `id`: integer, primary key
- `name`: string, presence: true, uniqueness: true (e.g., "Ground beef")
- `supermarket_section`: string, presence: true (e.g., "Butcher", "Produce")

### `dish_ingredients`
- `id`: integer, primary key
- `dish_id`: foreign key -> dishes.id
- `ingredient_id`: foreign key -> ingredients.id
- `suggested_quantity`: string, presence: true (e.g., "500g", "2 units")

## 4. Acceptance Criteria (Gherkin Scenarios)

### Scenario 1: Creating a dish with valid information
- **Given** I am on the new dish page
- **When** I fill in "Name" with "Pasta Bolognese" and select "Lunch" as "Category"
- **And** I save the dish
- **Then** I should see that "Pasta Bolognese" was successfully created.

### Scenario 2: Creating a dish with invalid category
- **Given** I try to save a dish with name "Pasta Bolognese" and category "InvalidCategory"
- **Then** the validation should fail and error message should be displayed.

### Scenario 3: Linking an ingredient to a dish
- **Given** a dish "Pasta Bolognese" exists
- **And** an ingredient "Tomato sauce" exists
- **When** I link "Tomato sauce" to "Pasta Bolognese" with quantity "1 can"
- **Then** the dish should list "Tomato sauce (1 can)" in its ingredients.
