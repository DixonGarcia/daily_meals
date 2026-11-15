# Feature Technical Implementation: Single-Owner Access Control

## 1. Data Model & Database Schema Changes
No new database tables are required. Authentication is statelessly verified against `ENV["APP_ACCESS_PASSWORD"]` using SHA-256 digests stored in Rails' encrypted cookie jar (`cookies.encrypted[:owner_session]`).

- **Environment Variables (`.env.example`)**:
  - `APP_ACCESS_PASSWORD`: Secret master password required to sign in via the web UI.
  - `GEMINI_API_KEY`: Secret API key for Google Gemini integration (prepared for `FEAT-04`).
  - `GEMINI_MODEL`: Optional model identifier (defaults to `gemini-2.5-flash`).

## 2. Controllers & Routing
- **Routes (`config/routes.rb`)**:
  - `resource :session, only: [:new, :create, :destroy]`
- **Base Controller (`ApplicationController`)**:
  - `before_action :require_authentication!`
  - `helper_method :authenticated?`
  - `authenticated?` computes `Digest::SHA256.hexdigest(ENV["APP_ACCESS_PASSWORD"].to_s)` (returning `false` immediately if `ENV["APP_ACCESS_PASSWORD"]` is blank) and compares it in constant time with `cookies.encrypted[:owner_session].to_s` via `ActiveSupport::SecurityUtils.secure_compare`.
- **Controller (`SessionsController`)**:
  - `skip_before_action :require_authentication!, only: [:new, :create]`
  - `rate_limit to: 5, within: 15.minutes, only: :create`
  - `new`: Renders login view (`app/views/sessions/new.html.erb`), or redirects to `root_path` if already `authenticated?`.
  - `create`: Extracts password using `params.expect(:password)`. Verifies against `ENV["APP_ACCESS_PASSWORD"]`. On match, writes `cookies.encrypted[:owner_session]` (`expires: 60.days.from_now`, `httponly: true`, `same_site: :lax`, `secure: Rails.env.production?`) and redirects to `root_path` with notice `t('sessions.controller.signed_in')`. On mismatch or blank env password, renders `:new` with status `:unprocessable_entity` and flash alert `t('sessions.controller.invalid_password')`.
  - `destroy`: Deletes `:owner_session` cookie and redirects to `new_session_path` with notice `t('sessions.controller.signed_out')`.

## 3. UI, Views & Locale i18n
- **Views**:
  - `app/views/sessions/new.html.erb`: Minimalist Biteclub login card with password input, show/hide toggle button, and submit CTA optimized for mobile (`412px` width) and desktop.
  - `app/views/layouts/application.html.erb`: Renders navigation links and the logout button (`button_to t('layout.logout'), session_path, method: :delete`) when `authenticated?` is true, with mobile-responsive wrapping on narrow viewports.
- **Locale File (`config/locales/es.yml`)**:
  ```yaml
  es:
    layout:
      logout: "🚪 Salir"
    sessions:
      new:
        title: "Acceso Privado"
        subtitle: "Ingresa tu clave maestra para gestionar tu plan semanal y lista de compras."
        password_label: "Clave de Acceso"
        password_placeholder: "Ingresa tu clave secreta..."
        toggle_password: "Mostrar u ocultar clave"
        submit: "🔓 Entrar a DailyMeals"
        persistence_note: "Tu sesión se mantendrá activa en este dispositivo por 60 días."
      controller:
        signed_in: "¡Bienvenido! Sesión iniciada con éxito."
        signed_out: "Has cerrado sesión correctamente."
        invalid_password: "La clave ingresada no es válida."
        unauthenticated: "Debes iniciar sesión para continuar."
        rate_limited: "Demasiados intentos fallidos. Espera unos minutos antes de volver a intentar."
  ```

## 4. Acceptance Criteria
- **Scenario 1: Unauthenticated user is redirected to login**
  - **Given** a visitor has no valid `owner_session` cookie
  - **When** they request `GET /`, `GET /dishes`, `GET /ingredients`, or `GET /api_keys`
  - **Then** they are redirected to `/session/new` with the alert `"Debes iniciar sesión para continuar."`
- **Scenario 2: Successful login with master password**
  - **Given** `ENV["APP_ACCESS_PASSWORD"]` is configured
  - **When** the owner submits the matching password to `POST /session`
  - **Then** an encrypted `owner_session` cookie is set for 60 days and they are redirected to `/` with notice `"¡Bienvenido! Sesión iniciada con éxito."`
- **Scenario 3: Invalid password rejection**
  - **Given** `ENV["APP_ACCESS_PASSWORD"]` is configured
  - **When** a visitor submits an incorrect password to `POST /session`
  - **Then** the response status is `422 Unprocessable Content`, no session cookie is set, and the alert `"La clave ingresada no es válida."` is rendered.
- **Scenario 4: Fail-closed when environment password is missing**
  - **Given** `ENV["APP_ACCESS_PASSWORD"]` is blank or unset
  - **When** any password is submitted to `POST /session`
  - **Then** login is denied with `422 Unprocessable Content`.
- **Scenario 5: Session invalidation upon password rotation or logout**
  - **Given** the owner has an active `owner_session` cookie
  - **When** they send `DELETE /session` (or `ENV["APP_ACCESS_PASSWORD"]` is rotated on the server)
  - **Then** subsequent requests to `/` redirect to `/session/new`.
