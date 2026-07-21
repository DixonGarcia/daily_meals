# Feature Specification: [Feature Name]

## 1. Goal & Context
Brief description of the feature, the problem it solves, and the business/user goals.

## 2. Requirements & User Stories
- **User Story 1**: As a user, I want to [action] so that [benefit].
- **User Story 2**: ...

## 3. Data Model & Schema Changes
- **Model Name**: `[ModelName]` (English, e.g. `DishCategory`)
- **Attributes / Fields**:
  - `name`: string (Spanish content stored in DB, e.g., `"Almuerzo"`)
  - `[attribute_name]`: [type]
- **Associations**:
  - `belongs_to :[other_model]`
  - `has_many :[other_models]`

## 4. Controllers & Routes
- **Controller**: `[Name]Controller` (English, e.g. `DishCategoriesController`)
  - `GET /path`: Description
  - `POST /path`: Description

## 5. UI Layout & Spanish i18n
- Views in Spanish under `app/views/`
- Text strings and flash messages defined in `config/locales/es.yml` (Spanish)
- Styling: Biteclub theme guidelines (`#ffffff`, `#141414`, `#9bc024`, `#0094e4`)

## 6. Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
