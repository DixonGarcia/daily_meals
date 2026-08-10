# Feature Overview: API Integration

## 1. Business Logic & Domain Context
The API Integration feature enables secure programmatic access to the DailyMeals application. By generating API keys, external clients (such as custom AI planning agents, scripts, or home automation tools) can interact with the system. This allows automated retrieval of the dish catalog and direct import of dishes and weekly meal plans without using the web UI.

## 2. Concepts & Domain Terminology
*   **API Key (Llave de API)**: A unique, cryptographically secure token passed in the headers of HTTP requests to authenticate the client.
*   **Token Digest (Hash de Token)**: A secure SHA256 digest of the API key stored in the database, ensuring that even if the database is compromised, the actual API keys cannot be read.
*   **Revocation (Revocación)**: The process of deactivating or deleting an API key, immediately blocking any subsequent requests authenticated with it.

## 3. Core Business Rules
*   **Authentication**: Every API endpoint requires a valid API key passed via the `X-Api-Key` HTTP header.
*   **Plain Text Visibility**: The raw API key token is shown to the user **exactly once** upon creation. It is never displayed again. In the list, only a masked version (e.g., `dmeal_live_...a8b3`) is shown.
*   **Security Standards**: Keys are matched using constant-time comparison against the stored SHA256 digest to prevent timing attacks.
*   **Atomicity**: Bulk imports (dishes or weekly plans) triggered via the API must be executed inside an database transaction. If any validation fails (e.g., a dish name is blank or a dish ID in a meal plan does not exist), the entire transaction rolls back and returns a `422 Unprocessable Content` response.
*   **Language Division**: The API payloads (keys and values) must be in English to match standard developer guidelines, while the UI settings and management messages must be in Spanish.

## 4. User Stories
*   **User Story 1**: As a user, I want to create a new API key with a custom name in the settings page, so that I can copy the generated token for my external assistant.
*   **User Story 2**: As a user, I want to see a list of my active keys along with their creation date and last used timestamp, so that I can audit key usage.
*   **User Story 3**: As a user, I want to delete (revoke) an API key instantly when it is no longer needed or if it is compromised, to prevent unauthorized access.
*   **User Story 4**: As an AI Copilot, I want to query the dishes and weekly plans using my API key, and submit imports of new dishes/plans programmatically.

## 5. Mockup Variations Overview
Under the `mockups/` folder, two layout variations are provided for comparison:
*   **Variant 1 (Tabla & Formulario)**:
    *   A list layout using a flat table to display active API keys.
    *   A static side form for generating new keys and inline warning dialogs for key deletion.
*   **Variant 2 (Tarjetas & Modal)**:
    *   A grid layout displaying API keys as dashboard cards.
    *   A clean popup modal that presents the generated key in plain text with a copy button immediately after creation.

## 6. Selected Variant
* **Selected Layout**: **Variant 2 (Cards & Modal Overlay)**
* **Rationale**: Provides a cleaner interface for displaying plain-text Bearer tokens in an isolated pop-up overlay immediately after creation, avoiding plain-text exposure on static side forms.

