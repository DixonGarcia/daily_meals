# Feature Overview: Single-Owner Access Control

## 1. Business Logic & Domain Context
DailyMeals is designed as a personal meal planning and shopping list application for a single owner, deployed under a custom public domain and accessed primarily from a mobile browser (such as a Samsung Galaxy S25+) and desktop browser. Because the application is exposed to the public internet and integrates with external AI services (Gemini API), it requires strict access control to prevent unauthorized visitors or bots from viewing or modifying meal plans, altering dish catalogs, managing API keys, or consuming AI quota—without introducing the complexity of multi-tenant user registration.

## 2. Concepts & Domain Terminology
*   **Master Access Password (Contraseña Maestra de Acceso)**: A secret credential configured exclusively via the server environment variable `APP_ACCESS_PASSWORD` (never stored in Git or hardcoded).
*   **Owner Session Cookie (Cookie de Sesión del Propietario)**: A cryptographically signed and encrypted HTTP-only cookie (`owner_session`) with a 60-day expiration window that keeps the owner logged in seamlessly on mobile and desktop browsers.
*   **Password Fingerprint Digest (Huella SHA-256)**: The SHA-256 digest of `APP_ACCESS_PASSWORD` stored inside the encrypted cookie. Rotating `APP_ACCESS_PASSWORD` on the server immediately invalidates all active browser sessions across devices.
*   **Fail-Closed Guard (Bloqueo Seguro por Defecto)**: If `APP_ACCESS_PASSWORD` is unset or blank on the server, authentication denies all login attempts rather than leaving the application open.

## 3. Core Business Rules
*   **Global Web Protection**: All web controllers inheriting from `ApplicationController` (`MealPlansController`, `DishesController`, `IngredientsController`, `ApiKeysController`, `AiCopilotsController`) must require a valid owner session before executing any action.
*   **Constant-Time Comparison**: Password verification and session digest validation must use `ActiveSupport::SecurityUtils.secure_compare` on SHA-256 digests to prevent timing attacks.
*   **Rate Limiting**: Login attempts at `POST /session` must be rate-limited (maximum 5 attempts within 15 minutes per IP) using Rails 8 native `rate_limit` to stop brute-force attacks.
*   **API v1 Independence**: Programmatic endpoints under `Api::V1::BaseController` remain authenticated exclusively via `Authorization: Bearer <token>` and are unaffected by browser cookie sessions.
*   **Healthcheck Accessibility**: The `/up` Rails health check endpoint remains publicly accessible for hosting load balancers and uptime monitors.
*   **Mobile-First Ergonomics**: Both the login screen and the main navigation bar (including the logout button) must render cleanly without horizontal overflow on a 412px mobile viewport (Samsung Galaxy S25+).

## 4. User Stories
*   **User Story 1**: As the application owner accessing DailyMeals from my phone on a public domain, I want to log in once with my master password and stay authenticated for 60 days so that I can check my shopping list and plan meals daily without friction.
*   **User Story 2**: As the application owner, I want unauthorized visitors to be redirected immediately to the login page whenever they request any page or submit any form, so that nobody on the internet can modify my meal plans or dishes.
*   **User Story 3**: As the application owner, I want to be able to log out explicitly from the navigation bar or invalidate all sessions by rotating `APP_ACCESS_PASSWORD` on my server.

## 5. Mockup Variations Overview
Under the `mockups/` folder, two layout variations are provided for comparison:
*   **Variant 1 (Tarjeta Bóveda Minimalista)**:
    *   A centered, mobile-first vault card with password visibility toggle, subtle security badge, and compact responsive navigation bar with an integrated logout button.
*   **Variant 2 (Panel Dividido Hero)**:
    *   A two-column split layout featuring a marketing-style side banner on desktop that collapses on mobile screens.
