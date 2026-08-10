# History

Registro de desarrollo de **DailyMeals**. Entradas en orden descendente (más reciente primero). Cada entrada cubre un ciclo lógico de feature o fix, independientemente del número de commits que lo componga.

---

## [FEAT-02] API Integration y Gestión de Llaves API — 2026-07-22

Se implementó acceso programático seguro a la aplicación mediante un sistema de llaves API Bearer. El objetivo fue permitir que clientes externos (agentes AI, scripts o herramientas de automatización) pudieran consultar el catálogo de platillos y planes de comida sin pasar por la interfaz web. El token se muestra una única vez al generarlo y nunca se almacena en texto plano.

Se creó el modelo `ApiKey` con la tabla `api_keys`, que almacena `name`, `token_digest` (SHA256 del token real), `active` y `last_used_at`. El `ApiKeysController` maneja la UI de gestión (index, create, destroy, update) con un modal emergente para la visualización única del token. Se introdujo el namespace `Api::V1::` con `Api::V1::BaseController` (hereda de `ActionController::API`) que autentica via `Authorization: Bearer <token>`, y los controladores `Api::V1::DishesController` y `Api::V1::MealPlansController` que exponen los endpoints `GET /api/v1/dishes`, `GET /api/v1/dishes/:id`, `GET /api/v1/meal_plans` y `GET /api/v1/meal_plans/:id`. La autenticación actualiza `last_used_at` en cada request válido.

Se eligió el layout Variant 2 (tarjetas + modal) sobre Variant 1 (tabla + formulario lateral). La suite RSpec cerró con 61 ejemplos y 0 fallos, cubriendo modelos, request specs de UI y request specs de la API v1 con y sin token.

---

## [FEAT-01] Planificación Semanal de Comidas — 2026-07-17

Se construyó el núcleo funcional de DailyMeals: el catálogo de platillos con sus ingredientes y la planificación semanal de comidas. El objetivo fue darle al usuario una forma de registrar qué cocinar cada día (almuerzo y cena) usando un catálogo propio, como paso previo a la generación automática de listas de compras.

Se crearon cuatro tablas: `dishes` (con `name` y `category`), `ingredients` (con `name` y `supermarket_section`), `dish_ingredients` (tabla de unión con `suggested_quantity` y constraint de unicidad compuesta sobre `dish_id` + `ingredient_id`) y `meal_plans` (con `day_of_week` unique, `lunch_dish_id` y `dinner_dish_id` como foreign keys a `dishes`). Los modelos `Dish`, `Ingredient`, `DishIngredient` y `MealPlan` se documentaron con YARD. Se crearon `DishesController`, `IngredientsController` y `MealPlansController` con acciones CRUD completas usando `params.expect` y métodos bang. Las vistas ERB se escribieron en español bajo el tema visual Biteclub (blanco `#ffffff`, verde lima `#9bc024`, azul `#0094e4`, bordes `#e9e9e9`). Toda la UI y los mensajes flash se gestionan via `config/locales/es.yml`.

En paralelo se estableció la infraestructura de agentes: las reglas en `.agents/rules/claude.md` (separación Inglés/Español, TDD, YARD, Rails 8 conventions) y las cuatro skills de workflow `build-spec`, `choose-mockup`, `build-feature` y `review-implementation` bajo `.agents/skills/`.

---

## [FEAT-00] Bootstrap del Proyecto — 2026-07-17

Se inicializó el proyecto DailyMeals como una aplicación Ruby on Rails 8.0 con PostgreSQL, RSpec y la estructura base del sistema de diseño Biteclub. Se definió la hoja de ruta de producto en `_product/` con especificaciones preliminares para los módulos `meal_planning`, `shopping_list`, `inventory_management`, `dashboard` y `ai_copilot`. Se configuró el archivo de estilos `application.css` con las variables de color y tokens del tema, y se estableció el rol PostgreSQL `dixon` como superuser para el entorno de desarrollo local.

---
