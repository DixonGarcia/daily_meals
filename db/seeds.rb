# Seed data for DailyMeals
# Includes base catalog items plus the complete 2172 kcal muscle-gain meal plan (@EstandoEnForma).

puts "Seeding ingredients..."
ingredients_data = [
  # Base ingredients
  { name: "Carne molida", supermarket_section: "Carnicería" },
  { name: "Papa", supermarket_section: "Verdulería" },
  { name: "Pasta", supermarket_section: "Víveres" },
  { name: "Salsa de tomate", supermarket_section: "Víveres" },
  { name: "Bisteck de res", supermarket_section: "Carnicería" },
  { name: "Pan pita", supermarket_section: "Panadería" },
  { name: "Lechuga", supermarket_section: "Verdulería" },

  # Proteins, meats, eggs & dairy (Plan 2172 kcal)
  { name: "Pechuga de pollo", supermarket_section: "Carnicería" },
  { name: "Pavo", supermarket_section: "Carnicería" },
  { name: "Jamón de pavo", supermarket_section: "Carnicería" },
  { name: "Carne magra de res", supermarket_section: "Carnicería" },
  { name: "Carne de cerdo magra", supermarket_section: "Carnicería" },
  { name: "Pescado", supermarket_section: "Carnicería" },
  { name: "Claras de huevo", supermarket_section: "Lácteos" },
  { name: "Huevo", supermarket_section: "Lácteos" },
  { name: "Leche deslactosada", supermarket_section: "Lácteos" },
  { name: "Whey protein", supermarket_section: "Otros" },

  # Grains, breads & complex carbs (Plan 2172 kcal)
  { name: "Pan integral", supermarket_section: "Panadería" },
  { name: "Pan pita integral", supermarket_section: "Panadería" },
  { name: "Avena en hojuelas", supermarket_section: "Víveres" },
  { name: "Harina de maíz", supermarket_section: "Víveres" },
  { name: "Arroz integral", supermarket_section: "Víveres" },
  { name: "Arroz blanco", supermarket_section: "Víveres" },
  { name: "Lentejas", supermarket_section: "Víveres" },
  { name: "Garbanzos", supermarket_section: "Víveres" },
  { name: "Quinoa", supermarket_section: "Víveres" },

  # Tubers & allowed vegetables (Plan 2172 kcal)
  { name: "Batata", supermarket_section: "Verdulería" },
  { name: "Yuca", supermarket_section: "Verdulería" },
  { name: "Aguacate", supermarket_section: "Verdulería" },
  { name: "Vegetales mixtos", supermarket_section: "Verdulería" },
  { name: "Cebolla", supermarket_section: "Verdulería" },
  { name: "Tomate", supermarket_section: "Verdulería" },
  { name: "Brócoli", supermarket_section: "Verdulería" },
  { name: "Calabacín", supermarket_section: "Verdulería" },
  { name: "Kale", supermarket_section: "Verdulería" },
  { name: "Coliflor", supermarket_section: "Verdulería" },
  { name: "Pimentón", supermarket_section: "Verdulería" },
  { name: "Champiñones", supermarket_section: "Verdulería" },
  { name: "Espárragos", supermarket_section: "Verdulería" },
  { name: "Espinaca", supermarket_section: "Verdulería" },
  { name: "Acelga", supermarket_section: "Verdulería" },
  { name: "Berenjena", supermarket_section: "Verdulería" },
  { name: "Palmito", supermarket_section: "Despensa" },

  # Fruits for Comida 1 & pre/post workout snack (Plan 2172 kcal)
  { name: "Fresas", supermarket_section: "Verdulería" },
  { name: "Banana", supermarket_section: "Verdulería" },
  { name: "Arándanos", supermarket_section: "Verdulería" },
  { name: "Piña", supermarket_section: "Verdulería" },
  { name: "Sandía", supermarket_section: "Verdulería" },
  { name: "Durazno", supermarket_section: "Verdulería" },
  { name: "Melón", supermarket_section: "Verdulería" },
  { name: "Moras", supermarket_section: "Verdulería" },
  { name: "Frambuesas", supermarket_section: "Verdulería" },
  { name: "Manzana", supermarket_section: "Verdulería" },
  { name: "Pera", supermarket_section: "Verdulería" },
  { name: "Naranja", supermarket_section: "Verdulería" },
  { name: "Mandarina", supermarket_section: "Verdulería" },

  # Healthy fats, nuts, dressings & beverages (Plan 2172 kcal)
  { name: "Aceite de oliva", supermarket_section: "Despensa" },
  { name: "Vinagre", supermarket_section: "Despensa" },
  { name: "Frutos secos mixtos", supermarket_section: "Despensa" },
  { name: "Nueces", supermarket_section: "Despensa" },
  { name: "Avellanas", supermarket_section: "Despensa" },
  { name: "Almendras", supermarket_section: "Despensa" },
  { name: "Maní", supermarket_section: "Despensa" },
  { name: "Pistachos", supermarket_section: "Despensa" },
  { name: "Mantequilla de maní", supermarket_section: "Despensa" },
  { name: "Gelatina light", supermarket_section: "Despensa" },
  { name: "Té verde", supermarket_section: "Bebidas" }
]

ingredients = {}
ingredients_data.each do |data|
  ingredient = Ingredient.find_or_initialize_by(name: data[:name])
  ingredient.supermarket_section = data[:supermarket_section]
  ingredient.save!
  ingredients[data[:name]] = ingredient
end

puts "Seeding dishes and associations..."
dishes_data = [
  # Original base dishes
  {
    name: "Carne molida con papas",
    categories: [ "Lunch" ],
    ingredients: [
      { name: "Carne molida", quantity: "500g" },
      { name: "Papa", quantity: "1 kg" }
    ]
  },
  {
    name: "Pasta boloñesa",
    categories: [ "Lunch" ],
    ingredients: [
      { name: "Carne molida", quantity: "500g" },
      { name: "Pasta", quantity: "500g" },
      { name: "Salsa de tomate", quantity: "1 lata" }
    ]
  },
  {
    name: "Shawarma de bisteck",
    categories: [ "Dinner" ],
    ingredients: [
      { name: "Bisteck de res", quantity: "400g" },
      { name: "Pan pita", quantity: "1 paquete" },
      { name: "Lechuga", quantity: "1 unidad" }
    ]
  },

  # ---------------------------------------------------------------------------
  # Comida 1 — Desayunos / Comidas ligeras (~287 kcal: 27g C | 29g P | 7g G)
  # ---------------------------------------------------------------------------
  {
    name: "Pan integral con claras de huevo y huevo cocido",
    categories: [ "Breakfast", "Dinner" ],
    ingredients: [
      { name: "Pan integral", quantity: "2 rebanadas" },
      { name: "Claras de huevo", quantity: "4 unidades" },
      { name: "Huevo", quantity: "1 unidad" }
    ]
  },
  {
    name: "Papas cocidas con pechuga de pollo y huevo cocido",
    categories: [ "Breakfast", "Dinner" ],
    ingredients: [
      { name: "Papa", quantity: "220g" },
      { name: "Pechuga de pollo", quantity: "80g" },
      { name: "Huevo", quantity: "1 unidad" }
    ]
  },
  {
    name: "Pan pita integral con pechuga de pollo y huevo cocido",
    categories: [ "Breakfast", "Dinner" ],
    ingredients: [
      { name: "Pan pita integral", quantity: "1 unidad" },
      { name: "Pechuga de pollo", quantity: "80g" },
      { name: "Huevo", quantity: "1 unidad" }
    ]
  },
  {
    name: "Batata cocida con claras de huevo y huevo cocido",
    categories: [ "Breakfast", "Dinner" ],
    ingredients: [
      { name: "Batata", quantity: "135g" },
      { name: "Claras de huevo", quantity: "4 unidades" },
      { name: "Huevo", quantity: "1 unidad" }
    ]
  },
  {
    name: "Arepa de avena con pechuga de pollo y huevo cocido",
    categories: [ "Breakfast", "Dinner" ],
    ingredients: [
      { name: "Avena en hojuelas", quantity: "55g" },
      { name: "Pechuga de pollo", quantity: "80g" },
      { name: "Huevo", quantity: "1 unidad" }
    ]
  },
  {
    name: "Avena con leche deslactosada y tortilla de claras",
    categories: [ "Breakfast" ],
    ingredients: [
      { name: "Avena en hojuelas", quantity: "40g" },
      { name: "Leche deslactosada", quantity: "150ml" },
      { name: "Claras de huevo", quantity: "3 unidades" },
      { name: "Huevo", quantity: "1 unidad" }
    ]
  },
  {
    name: "Tortilla española de papa y claras de huevo",
    categories: [ "Breakfast", "Dinner" ],
    ingredients: [
      { name: "Papa", quantity: "200g" },
      { name: "Claras de huevo", quantity: "4 unidades" },
      { name: "Cebolla", quantity: "50g" },
      { name: "Tomate", quantity: "50g" },
      { name: "Huevo", quantity: "1 unidad" }
    ]
  },
  {
    name: "Avena con banana y tortilla de claras con vegetales",
    categories: [ "Breakfast" ],
    ingredients: [
      { name: "Banana", quantity: "50g" },
      { name: "Avena en hojuelas", quantity: "25g" },
      { name: "Claras de huevo", quantity: "4 unidades" },
      { name: "Vegetales mixtos", quantity: "100g" },
      { name: "Huevo", quantity: "1 unidad" }
    ]
  },
  {
    name: "Sándwich de pan integral con jamón de pavo y huevo cocido",
    categories: [ "Breakfast", "Dinner" ],
    ingredients: [
      { name: "Pan integral", quantity: "2 rebanadas" },
      { name: "Jamón de pavo", quantity: "100g" },
      { name: "Huevo", quantity: "1 unidad" }
    ]
  },
  {
    name: "Arepa de maíz con jamón de pavo y huevo cocido",
    categories: [ "Breakfast", "Dinner" ],
    ingredients: [
      { name: "Harina de maíz", quantity: "40g" },
      { name: "Jamón de pavo", quantity: "100g" },
      { name: "Huevo", quantity: "1 unidad" }
    ]
  },

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
  },

  # ---------------------------------------------------------------------------
  # Meriendas y Pre/Post Entrenamiento (~282-346 kcal)
  # ---------------------------------------------------------------------------
  {
    name: "Tostadas integrales con mantequilla de maní y frutos secos",
    categories: [ "Snack" ],
    ingredients: [
      { name: "Pan integral", quantity: "2 rebanadas" },
      { name: "Mantequilla de maní", quantity: "15g" },
      { name: "Frutos secos mixtos", quantity: "25g" }
    ]
  },
  {
    name: "Avena cocida con frutos secos mixtos",
    categories: [ "Snack" ],
    ingredients: [
      { name: "Avena en hojuelas", quantity: "60g" },
      { name: "Frutos secos mixtos", quantity: "25g" }
    ]
  },
  {
    name: "Batido pre/post entreno de avena, whey protein y banana",
    categories: [ "Breakfast", "Snack" ],
    ingredients: [
      { name: "Avena en hojuelas", quantity: "40g" },
      { name: "Whey protein", quantity: "1 medida" },
      { name: "Banana", quantity: "100g" }
    ]
  },
  {
    name: "Bowl pre/post entreno de avena, whey protein y fresas",
    categories: [ "Breakfast", "Snack" ],
    ingredients: [
      { name: "Avena en hojuelas", quantity: "40g" },
      { name: "Whey protein", quantity: "1 medida" },
      { name: "Fresas", quantity: "300g" }
    ]
  },
  {
    name: "Avena pre/post entreno con claras de huevo y piña",
    categories: [ "Breakfast", "Snack" ],
    ingredients: [
      { name: "Avena en hojuelas", quantity: "40g" },
      { name: "Claras de huevo", quantity: "6 unidades" },
      { name: "Piña", quantity: "175g" }
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
