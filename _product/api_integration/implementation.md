# Feature Technical Implementation: API Integration

## 1. Data Model & Database Schema Changes
To support secure authentication, we require a database table to store the hashed API keys.

### Model Name: `ApiKey`
*   `name`: `string` (The user-provided label for the key, e.g., "AI assistant")
*   `token_digest`: `string` (The SHA256 hashed token stored in the database, with unique index)
*   `active`: `boolean` (Default `true`. Can be toggled to disable access)
*   `last_used_at`: `datetime` (Timestamp updated upon each successful API request)

### Migrations
```ruby
class CreateApiKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :api_keys do |t|
      t.string :name, null: false
      t.string :token_digest, null: false
      t.boolean :active, default: true, null: false
      t.datetime :last_used_at

      t.timestamps
    end
    add_index :api_keys, :token_digest, unique: true
  end
end
```

### Validations & Callbacks
*   `validates :name, presence: true`
*   `validates :token_digest, presence: true, uniqueness: true`
*   Generates a secure random token (e.g. using `SecureRandom.hex(24)`) when creating. Stores the hashed version via `Digest::SHA256.hexdigest(token)`.

---

## 2. Controllers & Routing

### Routes
```ruby
# UI Management
resources :api_keys, only: [:index, :create, :destroy, :update]

# API Endpoints
namespace :api do
  namespace :v1 do
    resources :dishes, only: [:index] do
      collection do
        post :import
      end
    end
    resources :meal_plans, only: [:index] do
      collection do
        post :import
      end
    end
  end
end
```

### Controllers

#### 1. `ApiKeysController` (UI Key Management)
*   `index`: Loads all active and inactive api keys. If a new key has just been created, passes the unhashed plain token to the view *once* via flash/session.
*   `create`: Instantiates a new API key. Expects `params.expect(api_key: [:name])`. Generates and returns the plain key for display.
*   `update`: Updates key parameters (specifically toggling `active` state or renaming). Expects `params.expect(api_key: [:name, :active])`.
*   `destroy`: Permanently deletes the key.

#### 2. `Api::V1::BaseController` (API Base)
*   Inherits from `ActionController::API` to omit sessions/cookies.
*   `before_action :authenticate_api_key!`
*   Extracts token from the HTTP `Authorization` header (Bearer token paradigm).
*   Hashes token value and compares in constant-time using Rails' built-in helper:
    ```ruby
    def authenticate_api_key!
      authenticate_with_http_token do |token, options|
        digest = Digest::SHA256.hexdigest(token)
        @api_key = ApiKey.find_by(token_digest: digest, active: true)

        if @api_key
          @api_key.update!(last_used_at: Time.current)
          true
        else
          false
        end
      end || head(:unauthorized)
    end
    ```

#### 3. `Api::V1::DishesController`
*   `index`: Returns a JSON array of all dishes with their categories and ingredients.
*   `import`: Imports a catalog of dishes. Expects `params.expect(:dishes => [...])`. Executed inside a transaction.

#### 4. `Api::V1::MealPlansController`
*   `index`: Returns a JSON representation of current meal plans.
*   `import`: Imports/consolidates a weekly schedule. Expects `params.expect(:meal_plan => [...])` (similar to the AI Copilot JSON payload). Executed inside a transaction.

---

## 3. UI, Views & Locale i18n
*   **Selected Layout**: **Variant 1 (List/Table style)** is chosen for the interface implementation.
*   **Views**: `app/views/api_keys/index.html.erb` containing the API key manager table and generation sidebar, styled in Biteclub.
*   **Locales**: Add translations to `config/locales/es.yml`:
    ```yaml
    es:
      api_keys:
        index:
          title: "🔑 Gestión de Llaves de API"
          create_key: "Generar Nueva Llave"
          revoke_key: "Revocar"
          name_label: "Nombre de la Llave"
          no_keys: "No tienes llaves de API creadas."
          copy_warning: "Copia tu llave de API ahora. No podrás volver a verla."
          created_at: "Creada el"
          last_used: "Último uso"
        controller:
          created: "Llave de API creada con éxito."
          revoked: "Llave de API revocada con éxito."
    ```

---

## 4. Acceptance Criteria

### Scenario 1: Accessing the API without a Key
*   **Given** that the application is running
*   **When** a client sends a `GET` request to `/api/v1/dishes` without an `Authorization` header
*   **Then** the response status must be `401 Unauthorized`

### Scenario 2: Accessing the API with a Valid Key
*   **Given** a valid and active `ApiKey` exists in the database
*   **When** a client sends a `GET` request to `/api/v1/dishes` with the `Authorization` header set to `"Bearer <valid_token>"`
*   **Then** the response status must be `200 OK` and return the list of dishes in JSON format

### Scenario 3: Creating a new API Key in the UI
*   **Given** the user is on the API Key settings page
*   **When** the user submits the form with the name "AI Assistant"
*   **Then** a new API Key is saved, a success message is shown, and the plain-text token is displayed *exactly once* for copying.

### Scenario 4: Revoking an API Key
*   **Given** a user is on the API Key settings page and has an existing key
*   **When** the user clicks "Revocar" on a key and confirms deletion
*   **Then** the key is deleted from the database and any subsequent API request using that token returns `401 Unauthorized`

### Scenario 5: Toggling the Active Status of an API Key
*   **Given** a valid and active `ApiKey` exists in the database
*   **When** the user toggles the status of the key (deactivates it)
*   **Then** the key's `active` attribute is set to `false`
*   **And** any subsequent API request using that token returns `401 Unauthorized`
*   **When** the user toggles the status again (reactivates it)
*   **Then** the key's `active` attribute is set to `true`
*   **And** subsequent API requests using that token return `200 OK`

