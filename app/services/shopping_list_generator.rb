# Generates a consolidated shopping list based on all active MealPlans.
# Counts repeated dish occurrences accurately, scales quantities by household servings,
# normalizes metric weights/volumes, fractions, and Spanish singular/plural units,
# and orders supermarket sections in canonical Venezuelan market stop sequence.
class ShoppingListGenerator
  # Default household servings multiplier when none is specified.
  DEFAULT_SERVINGS = 1
  # Maximum allowed household servings multiplier.
  MAX_SERVINGS = 10

  # Unicode fraction replacements normalized before regex parsing.
  UNICODE_FRACTIONS = {
    "½" => "1/2",
    "¼" => "1/4",
    "¾" => "3/4",
    "⅓" => "1/3",
    "⅔" => "2/3"
  }.freeze

  # Metric weight aliases mapped to their factor in grams.
  WEIGHT_UNITS = {
    "g" => 1.0,
    "gr" => 1.0,
    "grs" => 1.0,
    "gramo" => 1.0,
    "gramos" => 1.0,
    "kg" => 1000.0,
    "kilo" => 1000.0,
    "kilos" => 1000.0,
    "kilogramo" => 1000.0,
    "kilogramos" => 1000.0
  }.freeze

  # Metric volume aliases mapped to their factor in milliliters.
  VOLUME_UNITS = {
    "ml" => 1.0,
    "cc" => 1.0,
    "mililitro" => 1.0,
    "mililitros" => 1.0,
    "l" => 1000.0,
    "lt" => 1000.0,
    "lts" => 1000.0,
    "litro" => 1000.0,
    "litros" => 1000.0
  }.freeze

  # Spanish countable unit aliases mapped to [singular, plural] forms.
  COUNTABLE_UNITS = {
    "unidad" => [ "unidad", "unidades" ],
    "unidades" => [ "unidad", "unidades" ],
    "lata" => [ "lata", "latas" ],
    "latas" => [ "lata", "latas" ],
    "paquete" => [ "paquete", "paquetes" ],
    "paquetes" => [ "paquete", "paquetes" ],
    "rebanada" => [ "rebanada", "rebanadas" ],
    "rebanadas" => [ "rebanada", "rebanadas" ],
    "cucharada" => [ "cucharada", "cucharadas" ],
    "cucharadas" => [ "cucharada", "cucharadas" ],
    "cucharadita" => [ "cucharadita", "cucharaditas" ],
    "cucharaditas" => [ "cucharadita", "cucharaditas" ],
    "taza" => [ "taza", "tazas" ],
    "tazas" => [ "taza", "tazas" ],
    "diente" => [ "diente", "dientes" ],
    "dientes" => [ "diente", "dientes" ],
    "manojo" => [ "manojo", "manojos" ],
    "manojos" => [ "manojo", "manojos" ],
    "medida" => [ "medida", "medidas" ],
    "medidas" => [ "medida", "medidas" ],
    "cartón" => [ "cartón", "cartones" ],
    "cartones" => [ "cartón", "cartones" ],
    "bolsa" => [ "bolsa", "bolsas" ],
    "bolsas" => [ "bolsa", "bolsas" ],
    "botella" => [ "botella", "botellas" ],
    "botellas" => [ "botella", "botellas" ],
    "frasco" => [ "frasco", "frascos" ],
    "frascos" => [ "frasco", "frascos" ],
    "pieza" => [ "pieza", "piezas" ],
    "piezas" => [ "pieza", "piezas" ]
  }.freeze

  # Initializes the generator with a clamped household servings multiplier.
  #
  # @param servings [Integer] Number of household servings to multiply recipe quantities by (1..10).
  # @param meal_plans [Array<MealPlan>, nil] Optional preloaded MealPlan records to avoid duplicate queries.
  def initialize(servings: DEFAULT_SERVINGS, meal_plans: nil)
    parsed = servings.to_i
    @servings = parsed.between?(1, MAX_SERVINGS) ? parsed : DEFAULT_SERVINGS
    @meal_plans = meal_plans
  end

  # Generates the consolidated shopping list from all active weekly meal plan slots.
  #
  # @return [Hash{String => Array<Hash>}] Sections in canonical Ingredient::SECTIONS order mapped to
  #   arrays of item hashes ({ ingredient:, quantity:, dishes:, pantry_staple: }).
  def generate
    occurrences = collect_ingredient_occurrences
    return {} if occurrences.empty?

    raw_sections = {}

    occurrences.each do |ingredient, entries|
      quantities = entries.map { |entry| entry[:quantity] }
      dish_usage = entries.group_by { |entry| entry[:dish_name] }
                          .map { |name, list| { name: name, count: list.size } }
                          .sort_by { |d| d[:name] }

      section = ingredient.supermarket_section
      raw_sections[section] ||= []
      raw_sections[section] << {
        ingredient: ingredient,
        quantity: consolidate_quantities(quantities),
        dishes: dish_usage,
        pantry_staple: ingredient.pantry_staple?
      }
    end

    sort_sections(raw_sections)
  end

  # Generates the shopping list partitioned into weekly fresh items and pantry staples.
  #
  # @return [Hash] Hash containing :fresh, :pantry, :fresh_count, :pantry_count, and :total_count.
  def generate_grouped
    full_list = generate
    fresh = {}
    pantry = {}
    fresh_count = 0
    pantry_count = 0

    full_list.each do |section, items|
      fresh_items, pantry_items = items.partition { |item| !item[:pantry_staple] }

      if fresh_items.any?
        fresh[section] = fresh_items
        fresh_count += fresh_items.size
      end

      if pantry_items.any?
        pantry[section] = pantry_items
        pantry_count += pantry_items.size
      end
    end

    {
      fresh: fresh,
      pantry: pantry,
      fresh_count: fresh_count,
      pantry_count: pantry_count,
      total_count: fresh_count + pantry_count
    }
  end

  private

  # Iterates over every scheduled lunch and dinner slot (preserving duplicate dishes)
  # and aggregates ingredient occurrences without N+1 queries.
  #
  # @return [Hash{Ingredient => Array<Hash>}]
  def collect_ingredient_occurrences
    plans = @meal_plans || MealPlan.includes(
      lunch_dish: { dish_ingredients: :ingredient },
      dinner_dish: { dish_ingredients: :ingredient }
    ).all

    occurrences = Hash.new { |hash, key| hash[key] = [] }

    plans.each do |plan|
      [ plan.lunch_dish, plan.dinner_dish ].compact.each do |dish|
        dish.dish_ingredients.each do |dish_ingredient|
          occurrences[dish_ingredient.ingredient] << {
            quantity: dish_ingredient.suggested_quantity,
            dish_name: dish.name
          }
        end
      end
    end

    occurrences
  end

  # Orders section keys by Ingredient::SECTIONS canonical order and sorts items alphabetically.
  #
  # @param sections_hash [Hash{String => Array<Hash>}]
  # @return [Hash{String => Array<Hash>}]
  def sort_sections(sections_hash)
    ordered_keys = sections_hash.keys.sort_by do |section|
      Ingredient::SECTIONS.index(section) || Ingredient::SECTIONS.length
    end

    ordered_keys.each_with_object({}) do |section, sorted|
      sorted[section] = sections_hash[section].sort_by { |item| item[:ingredient].name }
    end
  end

  # Parses, scales by @servings, normalizes compatible units, and sums quantities.
  #
  # @param quantities [Array<String>] The raw quantities to consolidate.
  # @return [String] Formatted consolidated quantity string.
  def consolidate_quantities(quantities)
    return "" if quantities.empty?

    parsed_items = quantities.map { |raw| parse_quantity(raw) }
    grouped = parsed_items.group_by { |item| item[:group_key] }

    parts = grouped.map do |group_key, items|
      format_group(group_key, items)
    end

    parts.join(" + ")
  end

  # Parses a single quantity string into a normalized numeric/unit hash scaled by @servings.
  #
  # @param raw [String] Raw quantity string (e.g., "500g", "1/2 kg", "½ paquete", "1,5 L").
  # @return [Hash]
  def parse_quantity(raw)
    cleaned = raw.to_s.strip
    UNICODE_FRACTIONS.each { |char, ascii| cleaned = cleaned.gsub(char, ascii) }
    cleaned = cleaned.gsub(/(\d),(\d)/, '\1.\2')

    match = cleaned.match(/\A(?:(\d+)\s+(\d+)\/(\d+)|(\d+)\/(\d+)|(\d+(?:\.\d+)?))(\s*)(.*)\z/)
    unless match
      return { numeric: false, group_key: "text:#{cleaned.downcase}", raw_text: cleaned }
    end

    value = extract_numeric_value(match)
    unless value
      return { numeric: false, group_key: "text:#{cleaned.downcase}", raw_text: cleaned }
    end

    scaled_value = value * @servings
    spacing = match[7]
    unit = match[8].to_s.strip
    unit_key = unit.downcase

    if WEIGHT_UNITS.key?(unit_key)
      { numeric: true, group_key: :weight, val: scaled_value * WEIGHT_UNITS[unit_key] }
    elsif VOLUME_UNITS.key?(unit_key)
      { numeric: true, group_key: :volume, val: scaled_value * VOLUME_UNITS[unit_key] }
    elsif COUNTABLE_UNITS.key?(unit_key)
      singular, plural = COUNTABLE_UNITS[unit_key]
      { numeric: true, group_key: "countable:#{singular}", val: scaled_value, singular: singular, plural: plural }
    else
      { numeric: true, group_key: "unit:#{unit_key}", val: scaled_value, spacing: spacing, unit: unit }
    end
  end

  # Extracts a float from regex match groups for mixed fractions, simple fractions, or decimals.
  #
  # @param match [MatchData]
  # @return [Float, nil]
  def extract_numeric_value(match)
    if match[1] && match[2] && match[3]
      denominator = match[3].to_f
      return nil if denominator.zero?

      match[1].to_f + (match[2].to_f / denominator)
    elsif match[4] && match[5]
      denominator = match[5].to_f
      return nil if denominator.zero?

      match[4].to_f / denominator
    elsif match[6]
      match[6].to_f
    end
  end

  # Formats a single normalized unit group back into a clean human-readable string.
  #
  # @param group_key [Symbol, String]
  # @param items [Array<Hash>]
  # @return [String]
  def format_group(group_key, items)
    return format_non_numeric_group(items) unless items.first[:numeric]

    total = items.sum { |item| item[:val] }

    case group_key
    when :weight
      if total >= 1000.0
        "#{format_number(total / 1000.0)} kg"
      else
        "#{format_number(total)}g"
      end
    when :volume
      if total >= 1000.0
        "#{format_number(total / 1000.0)} L"
      else
        "#{format_number(total)}ml"
      end
    else
      if group_key.to_s.start_with?("countable:")
        label = (total - 1.0).abs < 1e-6 ? items.first[:singular] : items.first[:plural]
        "#{format_number(total)} #{label}"
      else
        original_unit = items.map { |i| i[:unit] }.find(&:present?) || ""
        spacing = items.map { |i| i[:spacing] }.find { |s| !s.nil? } || ""
        "#{format_number(total)}#{spacing}#{original_unit}"
      end
    end
  end

  # Formats non-numeric free-text quantities without losing duplicate occurrences.
  #
  # @param items [Array<Hash>]
  # @return [String]
  def format_non_numeric_group(items)
    label = items.first[:raw_text]
    count = items.size
    count > 1 ? "#{label} (×#{count})" : label
  end

  # Formats numeric quantities cleanly without trailing zeros (e.g., 1.0 => "1", 1.10 => "1.1").
  #
  # @param value [Float]
  # @return [String]
  def format_number(value)
    rounded = value.round(2)
    return rounded.to_i.to_s if (rounded % 1).zero?

    format("%.2f", rounded).sub(/0+\z/, "")
  end
end
