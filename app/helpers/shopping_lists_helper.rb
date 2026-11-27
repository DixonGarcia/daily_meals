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

  # Formats dish usage metadata into a compact human-readable subtitle for 1–2 dishes.
  #
  # @param dishes [Array<Hash>] Array of { name: String, count: Integer } entries.
  # @return [String] Compact summary such as "Pollo con arroz (×2) · Carne con papas".
  def format_dish_usage(dishes)
    Array(dishes).map { |entry| format_single_dish_usage(entry) }.join(" · ")
  end

  # Formats a single dish usage entry with optional multiplicity suffix.
  #
  # @param entry [Hash] Hash containing :name and :count.
  # @return [String]
  def format_single_dish_usage(entry)
    entry[:count].to_i > 1 ? "#{entry[:name]} (×#{entry[:count]})" : entry[:name].to_s
  end

  # Counts total scheduled meal slots across all dish usage entries.
  #
  # @param dishes [Array<Hash>] Array of { name: String, count: Integer } entries.
  # @return [Integer]
  def total_dish_occurrences(dishes)
    Array(dishes).sum { |entry| entry[:count].to_i }
  end
end
