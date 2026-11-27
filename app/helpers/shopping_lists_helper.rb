# View helpers for rendering Venezuelan market stop emojis and dish usage summaries.
module ShoppingListsHelper
  # Visual emoji mapping for each canonical supermarket section.
  SECTION_EMOJIS = {
    "Verdulería" => "🥬",
    "Carnicería" => "🥩",
    "Charcutería" => "🧀",
    "Lácteos" => "🥛",
    "Panadería" => "🥖",
    "Víveres" => "🥫",
    "Despensa" => "🏠",
    "Congelados" => "❄️",
    "Bebidas" => "🥤",
    "Limpieza" => "🧼",
    "Otros" => "📦"
  }.freeze

  # Returns the emoji associated with a supermarket section name.
  #
  # @param section [String] Supermarket section name.
  # @return [String] Matching emoji or default box icon.
  def shopping_section_emoji(section)
    SECTION_EMOJIS.fetch(section.to_s, "📦")
  end

  # Formats dish usage metadata into a compact human-readable subtitle.
  #
  # @param dishes [Array<Hash>] Array of { name: String, count: Integer } entries.
  # @return [String] Compact summary such as "Pollo a la plancha (×2) · Carne magra".
  def format_dish_usage(dishes)
    Array(dishes).map do |entry|
      entry[:count].to_i > 1 ? "#{entry[:name]} (×#{entry[:count]})" : entry[:name]
    end.join(" · ")
  end
end
