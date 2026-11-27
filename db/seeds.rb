# Seed data for DailyMeals
# Focused strictly on Lunch & Dinner dishes from the 2172 kcal meal plan (@EstandoEnForma).
# Breakfasts, snacks, and legacy demo dishes are intentionally excluded.

puts "Seeding ingredients..."
ingredients_data = [
  # Proteins & meats (Lunch & Dinner)
  { name: "Pechuga de pollo", supermarket_section: "Carnicería", pantry_staple: false },
  { name: "Pavo", supermarket_section: "Carnicería", pantry_staple: false },
  { name: "Carne magra de res", supermarket_section: "Carnicería", pantry_staple: false },
  { name: "Carne de cerdo magra", supermarket_section: "Carnicería", pantry_staple: false },
  { name: "Pescado", supermarket_section: "Carnicería", pantry_staple: false },

  # Grains & legumes (pantry staples bought biweekly/monthly)
  { name: "Arroz integral", supermarket_section: "Víveres", pantry_staple: true },
  { name: "Arroz blanco", supermarket_section: "Víveres", pantry_staple: true },
  { name: "Lentejas", supermarket_section: "Víveres", pantry_staple: true },
  { name: "Garbanzos", supermarket_section: "Víveres", pantry_staple: true },
  { name: "Quinoa", supermarket_section: "Víveres", pantry_staple: true },

  # Fresh produce & tubers (weekly market / feria)
  { name: "Papa", supermarket_section: "Verdulería", pantry_staple: false },
  { name: "Batata", supermarket_section: "Verdulería", pantry_staple: false },
  { name: "Yuca", supermarket_section: "Verdulería", pantry_staple: false },
  { name: "Aguacate", supermarket_section: "Verdulería", pantry_staple: false },
  { name: "Vegetales mixtos", supermarket_section: "Verdulería", pantry_staple: false },
  { name: "Cebolla", supermarket_section: "Verdulería", pantry_staple: false },
  { name: "Tomate", supermarket_section: "Verdulería", pantry_staple: false },
  { name: "Brócoli", supermarket_section: "Verdulería", pantry_staple: false },
  { name: "Calabacín", supermarket_section: "Verdulería", pantry_staple: false },
  { name: "Coliflor", supermarket_section: "Verdulería", pantry_staple: false },
  { name: "Pimentón", supermarket_section: "Verdulería", pantry_staple: false },
  { name: "Espinaca", supermarket_section: "Verdulería", pantry_staple: false },
  { name: "Berenjena", supermarket_section: "Verdulería", pantry_staple: false },

  # Pantry fats & dressings
  { name: "Aceite de oliva", supermarket_section: "Despensa", pantry_staple: true },
  { name: "Vinagre", supermarket_section: "Despensa", pantry_staple: true }
]

ingredients = {}
ingredients_data.each do |data|
  ingredient = Ingredient.find_or_initialize_by(name: data[:name])
  ingredient.supermarket_section = data[:supermarket_section]
  ingredient.pantry_staple = data[:pantry_staple]
  ingredient.save!
  ingredients[data[:name]] = ingredient
end

puts "Seeding lunch & dinner dishes..."
dishes_data = [
  # ---------------------------------------------------------------------------
  # Comida 2 — Almuerzos y Cenas (~507 kcal: 52g C | 32g P | 19g G)
  # ---------------------------------------------------------------------------
  {
    name: "Pollo a la plancha con arroz integral y vegetales",
    categories: [ "Lunch", "Dinner" ],
    ingredients: [
      { name: "Arroz integral", quantity: "160g" },
      { name: "Pechuga de pollo", quantity: "90g" },
      { name: "Vegetales mixtos", quantity: "200g" },
      { name: "Aceite de oliva", quantity: "15ml" }
    ]
  },
  {
    name: "Lentejas guisadas con pollo a la plancha y vegetales",
    categories: [ "Lunch", "Dinner" ],
    ingredients: [
      { name: "Lentejas", quantity: "240g" },
      { name: "Pechuga de pollo", quantity: "35g" },
      { name: "Vegetales mixtos", quantity: "200g" },
      { name: "Aceite de oliva", quantity: "15ml" }
    ]
  },
  {
    name: "Pollo a la plancha con arroz blanco y vegetales",
    categories: [ "Lunch", "Dinner" ],
    ingredients: [
      { name: "Arroz blanco", quantity: "160g" },
      { name: "Pechuga de pollo", quantity: "90g" },
      { name: "Vegetales mixtos", quantity: "200g" },
      { name: "Aceite de oliva", quantity: "15ml" }
    ]
  },
  {
    name: "Garbanzos con pollo a la plancha y vegetales",
    categories: [ "Lunch", "Dinner" ],
    ingredients: [
      { name: "Garbanzos", quantity: "165g" },
      { name: "Pechuga de pollo", quantity: "55g" },
      { name: "Vegetales mixtos", quantity: "200g" },
      { name: "Aceite de oliva", quantity: "15ml" }
    ]
  },
  {
    name: "Pollo a la plancha con papas al vapor y vegetales",
    categories: [ "Lunch", "Dinner" ],
    ingredients: [
      { name: "Papa", quantity: "360g" },
      { name: "Pechuga de pollo", quantity: "90g" },
      { name: "Vegetales mixtos", quantity: "200g" },
      { name: "Aceite de oliva", quantity: "15ml" }
    ]
  },
  {
    name: "Pollo a la plancha con batata asada y vegetales",
    categories: [ "Lunch", "Dinner" ],
    ingredients: [
      { name: "Batata", quantity: "220g" },
      { name: "Pechuga de pollo", quantity: "90g" },
      { name: "Vegetales mixtos", quantity: "200g" },
      { name: "Aceite de oliva", quantity: "15ml" }
    ]
  },
  {
    name: "Bowl de quinoa con pollo a la plancha y vegetales",
    categories: [ "Lunch", "Dinner" ],
    ingredients: [
      { name: "Quinoa", quantity: "175g" },
      { name: "Pechuga de pollo", quantity: "80g" },
      { name: "Vegetales mixtos", quantity: "200g" },
      { name: "Aceite de oliva", quantity: "15ml" }
    ]
  },
  {
    name: "Pollo a la plancha con yuca cocida y vegetales",
    categories: [ "Lunch", "Dinner" ],
    ingredients: [
      { name: "Yuca", quantity: "120g" },
      { name: "Pechuga de pollo", quantity: "90g" },
      { name: "Vegetales mixtos", quantity: "200g" },
      { name: "Aceite de oliva", quantity: "15ml" }
    ]
  },

  # ---------------------------------------------------------------------------
  # Comida 3 — Post-Entreno Alta en Carbohidratos & Sustituciones (~736 kcal: 98g C | 32g P | 24g G)
  # ---------------------------------------------------------------------------
  {
    name: "Carne magra a la plancha con arroz integral y aguacate (Post-entreno)",
    categories: [ "Lunch", "Dinner" ],
    ingredients: [
      { name: "Arroz integral", quantity: "320g" },
      { name: "Carne magra de res", quantity: "110g" },
      { name: "Vegetales mixtos", quantity: "200g" },
      { name: "Aguacate", quantity: "155g" }
    ]
  },
  {
    name: "Lentejas con carne magra y aguacate (Post-entreno)",
    categories: [ "Lunch", "Dinner" ],
    ingredients: [
      { name: "Lentejas", quantity: "480g" },
      { name: "Carne magra de res", quantity: "45g" },
      { name: "Vegetales mixtos", quantity: "200g" },
      { name: "Aguacate", quantity: "155g" }
    ]
  },
  {
    name: "Pescado a la plancha con arroz blanco y aguacate (Post-entreno)",
    categories: [ "Lunch", "Dinner" ],
    ingredients: [
      { name: "Arroz blanco", quantity: "320g" },
      { name: "Pescado", quantity: "120g" },
      { name: "Vegetales mixtos", quantity: "200g" },
      { name: "Aguacate", quantity: "155g" }
    ]
  },
  {
    name: "Garbanzos con lomo de cerdo magro y vegetales (Post-entreno)",
    categories: [ "Lunch", "Dinner" ],
    ingredients: [
      { name: "Garbanzos", quantity: "330g" },
      { name: "Carne de cerdo magra", quantity: "80g" },
      { name: "Vegetales mixtos", quantity: "200g" },
      { name: "Aceite de oliva", quantity: "20ml" }
    ]
  },
  {
    name: "Carne magra con papas al horno y aguacate (Post-entreno)",
    categories: [ "Lunch", "Dinner" ],
    ingredients: [
      { name: "Papa", quantity: "720g" },
      { name: "Carne magra de res", quantity: "110g" },
      { name: "Vegetales mixtos", quantity: "200g" },
      { name: "Aguacate", quantity: "155g" }
    ]
  },
  {
    name: "Pavo a la plancha con batata y aguacate (Post-entreno)",
    categories: [ "Lunch", "Dinner" ],
    ingredients: [
      { name: "Batata", quantity: "440g" },
      { name: "Pavo", quantity: "100g" },
      { name: "Vegetales mixtos", quantity: "200g" },
      { name: "Aguacate", quantity: "155g" }
    ]
  },
  {
    name: "Bowl de quinoa con pescado a la plancha y aguacate (Post-entreno)",
    categories: [ "Lunch", "Dinner" ],
    ingredients: [
      { name: "Quinoa", quantity: "350g" },
      { name: "Pescado", quantity: "110g" },
      { name: "Vegetales mixtos", quantity: "200g" },
      { name: "Aguacate", quantity: "155g" }
    ]
  },
  {
    name: "Cerdo magro a la plancha con yuca y aguacate (Post-entreno)",
    categories: [ "Lunch", "Dinner" ],
    ingredients: [
      { name: "Yuca", quantity: "140g" },
      { name: "Carne de cerdo magra", quantity: "120g" },
      { name: "Vegetales mixtos", quantity: "200g" },
      { name: "Aguacate", quantity: "155g" }
    ]
  }
]

dishes_data.each do |data|
  dish = Dish.find_or_initialize_by(name: data[:name])
  dish.categories = data[:categories]
  dish.save!

  data[:ingredients].each do |ing_data|
    ingredient = ingredients.fetch(ing_data[:name])
    dish_ing = DishIngredient.find_or_initialize_by(dish: dish, ingredient: ingredient)
    dish_ing.suggested_quantity = ing_data[:quantity]
    dish_ing.save!
  end
end

puts "Database seeded successfully! (#{Ingredient.count} ingredients, #{Dish.count} dishes)"
