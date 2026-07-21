# Feature Technical Implementation: [Feature/Domain Name]

## 1. Data Model & Database Schema Changes
*Define database tables, columns, constraints, and relationships. All code, database objects, and keys must be in English.*

- **Model Name**: `[ModelName]`
  - `[attribute_name]`: [type] (e.g. `name: string` - note that database content data itself is stored in Spanish)
- **Associations**:
  - `belongs_to :[association]`
  - `has_many :[association]`
- **Validations & Constraints**:
  - `validates :name, presence: true`

## 2. Controllers & Routing
*Define Rails routing endpoints and controller structures. All names and parameters must be in English.*

- **Routes**:
  - `resources :[resources_name], only: [:index, :new, :create]`
- **Controller**: `[Name]Controller`
  - Action methods and parameter requirements. Use `params.expect` (Rails 8+ syntax).

## 3. UI, Views & Locale i18n
*Define user-facing interfaces, translations, and templates. All UI text, alerts, buttons, and validation messages must be in Spanish via locales.*

- **Views**: `app/views/[directory]/` templates using ERB and standard Biteclub style.
- **Locale File**: Add keys to `config/locales/es.yml`:
  ```yaml
  es:
    [controller_name]:
      [action_name]:
        success: "¡[Action] exitosa!"
        failure: "Error al [action]."
  ```

## 4. Acceptance Criteria
*Gherkin-style scenarios describing behavior to be covered in model/request specs.*
- **Scenario**: [Scenario Name]
  - **Given** [preconditions]
  - **When** [actions]
  - **Then** [expected outcomes]
