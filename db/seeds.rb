# Seed data for DailyMeals

puts "Seeding ingredients..."
ingredients_data = [
  { name: "Carne molida", supermarket_section: "Carnicería" },
  { name: "Papa", supermarket_section: "Verdulería" },
  { name: "Pasta", supermarket_section: "Víveres" },
  { name: "Salsa de tomate", supermarket_section: "Víveres" },
  { name: "Bisteck de res", supermarket_section: "Carnicería" },
  { name: "Pan pita", supermarket_section: "Víveres" },
  { name: "Lechuga", supermarket_section: "Verdulería" }
]

ingredients = {}
ingredients_data.each do |data|
  ingredients[data[:name]] = Ingredient.find_or_create_by!(name: data[:name]) do |ing|
    ing.supermarket_section = data[:supermarket_section]
  end
end

puts "Seeding dishes and associations..."
dishes_data = [
  {
    name: "Carne molida con papas",
    category: "Lunch",
    ingredients: [
      { name: "Carne molida", quantity: "500g" },
      { name: "Papa", quantity: "1 kg" }
    ]
  },
  {
    name: "Pasta boloñesa",
    category: "Lunch",
    ingredients: [
      { name: "Carne molida", quantity: "500g" },
      { name: "Pasta", quantity: "500g" },
      { name: "Salsa de tomate", quantity: "1 lata" }
    ]
  },
  {
    name: "Shawarma de bisteck",
    category: "Dinner",
    ingredients: [
      { name: "Bisteck de res", quantity: "400g" },
      { name: "Pan pita", quantity: "1 paquete" },
      { name: "Lechuga", quantity: "1 unidad" }
    ]
  }
]

dishes_data.each do |data|
  dish = Dish.find_or_create_by!(name: data[:name]) do |d|
    d.category = data[:category]
  end

  data[:ingredients].each do |ing_data|
    ingredient = ingredients[ing_data[:name]]
    DishIngredient.find_or_create_by!(dish: dish, ingredient: ingredient) do |di|
      di.suggested_quantity = ing_data[:quantity]
    end
  end
end

puts "Database seeded successfully!"
