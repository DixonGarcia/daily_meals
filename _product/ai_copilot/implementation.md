# Feature Technical Implementation: Persistent Gemini Pseudo-Chat & Guided Menu Loader

## 1. Data Model & Database Schema Changes

- **Model Name**: `AiChatSession` (`ai_chat_sessions` table)
  - `title`: `string`, `null: false`
  - `parameters`: `jsonb`, `null: false`, `default: {}` (keys in English: `days`, `include_lunch`, `include_dinner`, `avoid_repetition`)
  - `proposed_plan`: `jsonb`, `null: false`, `default: []` (array of `{ "day" => "Monday", "lunch_dish_id" => 1, "dinner_dish_id" => 2 }`)
  - `status`: `string`, `null: false`, `default: "active"` (`"active"` or `"applied"`)
  - `timestamps`
  - **Associations**: `has_many :ai_chat_messages, -> { order(:created_at, :id) }, dependent: :destroy`
  - **Validations**: `validates :title, presence: true`, `validates :status, inclusion: { in: %w[active applied] }`

- **Model Name**: `AiChatMessage` (`ai_chat_messages` table)
  - `ai_chat_session_id`: `bigint`, `null: false`, foreign key (`ai_chat_sessions`)
  - `role`: `string`, `null: false` (`"user"` or `"assistant"`)
  - `content`: `text`, `null: false`
  - `proposed_plan`: `jsonb`, `null: false`, `default: []`
  - `timestamps`
  - **Associations**: `belongs_to :ai_chat_session`
  - **Validations**: `validates :role, inclusion: { in: %w[user assistant] }`, `validates :content, presence: true`

## 2. Services, Controllers & Routing

- **Service**: `GeminiClient` (`app/services/gemini_client.rb`)
  - Uses standard library `Net::HTTP` and `JSON` to call `https://generativelanguage.googleapis.com/v1beta/models/#{model}:generateContent` with header `x-goog-api-key: ENV["GEMINI_API_KEY"]`.
  - Requests `responseMimeType: "application/json"` with a strict `responseSchema` requiring `reply` (String) and `meal_plan` (Array of `{ day, lunch_dish_id, dinner_dish_id }`).
  - Raises `GeminiClient::ConfigurationError` when `GEMINI_API_KEY` is blank and `GeminiClient::ApiError` on network/API failure.

- **Service**: `AiCopilotService` (`app/services/ai_copilot_service.rb`)
  - Retains `export_catalog(restrictions)` and `import_plan(payload)` for backward compatibility.
  - Adds `converse!(session:, user_message:, parameters: {})`:
    1. Updates `session.parameters` if provided.
    2. Persists the user's `AiChatMessage` (`role: "user"`).
    3. Builds the system prompt containing the current `Dish` catalog (`id`, `name`, `category`), current `MealPlan` schedule, and active `session.parameters`.
    4. Calls `GeminiClient#generate_plan_response(system_instruction:, messages:)`.
    5. Sanitizes `meal_plan` entries against valid `Dish.pluck(:id)` and `MealPlan::DAYS_OF_WEEK`.
    6. Persists the assistant's `AiChatMessage` (`role: "assistant"`, `content: reply`, `proposed_plan: sanitized_plan`) and updates `session.proposed_plan` when non-empty.
  - Adds `apply_session_plan!(session)`:
    - Atomically imports `session.proposed_plan` into `MealPlan` and marks `session.update!(status: "applied")`.

- **Routes (`config/routes.rb`)**:
  - `resources :ai_chat_sessions, only: [:create, :destroy] do`
    - `member { post :apply; patch :switch }`
    - `resources :ai_chat_messages, only: [:create]`
  - `end`

- **Controllers**:
  - `AiChatSessionsController`:
    - `create`: Creates a new `AiChatSession` with default parameters and stores `session[:active_ai_chat_session_id]`.
    - `switch`: Switches `session[:active_ai_chat_session_id]` to the selected historical session.
    - `apply`: Calls `AiCopilotService.new.apply_session_plan!(chat_session)` and redirects to `root_path` with success notice.
    - `destroy`: Deletes a chat session and redirects to `root_path`.
  - `AiChatMessagesController`:
    - Rate-limited (`rate_limit to: 15, within: 5.minutes, only: :create`).
    - Extracts message and parameters via `params.expect`, invokes `AiCopilotService.new.converse!`, and redirects cleanly to `root_path(anchor: "ai-copilot-panel")`.

## 3. UI, Views & Locale i18n
- **Dashboard (`app/views/meal_plans/index.html.erb`)**:
  - Displays the integrated Gemini Pseudo-Chat card in the sidebar with:
    - Session selector dropdown + "➕ Nueva charla" button.
    - Parameter toggles (Días: Lunes–Viernes vs. Lunes–Domingo, Almuerzo, Cena, Evitar repetir platos).
    - Scrollable message history (`user` and `assistant` bubbles).
    - Proposed Weekly Menu Preview box (mapping dish IDs to Spanish dish names) with the **"📥 Cargar Menú en el Calendario"** CTA button whenever `proposed_plan` is present.
    - Collapsible secondary accordion for legacy manual JSON export/import fallback.

## 4. Acceptance Criteria
- **Scenario 1: Sending a chat message with planning parameters**
  - **Given** dishes exist in the catalog and `GEMINI_API_KEY` is configured
  - **When** the owner submits a message *"Armame el menú de lunes a viernes sin repetir carnes"* with parameters selected
  - **Then** the user message and Gemini's structured reply + `proposed_plan` are persisted in PostgreSQL and displayed in the chat panel.
- **Scenario 2: Sanitizing hallucinated dish IDs**
  - **Given** Gemini returns a `meal_plan` referencing a non-existent `lunch_dish_id: 99999`
  - **When** `AiCopilotService#converse!` processes the response
  - **Then** `lunch_dish_id` is sanitized to `nil` so no invalid foreign key is stored.
- **Scenario 3: Applying the proposed menu to the weekly calendar**
  - **Given** an `AiChatSession` has a non-empty `proposed_plan`
  - **When** the owner clicks **"📥 Cargar Menú en el Calendario"** (`POST /ai_chat_sessions/:id/apply`)
  - **Then** `MealPlan` records are updated atomically, the session status becomes `"applied"`, and the shopping list reflects the new dishes.
