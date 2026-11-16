# Stores weekly snapshots of the Monday-Sunday MealPlan calendar for archival and restoration.
class MealPlanHistory < ApplicationRecord
  SOURCES = %w[manual ai_copilot restore].freeze

  validates :year, :week_number, :week_start_date, :week_end_date, :source, presence: true
  validates :week_number, uniqueness: { scope: :year }, inclusion: { in: 1..53 }
  validates :source, inclusion: { in: SOURCES }

  # Captures or updates the ISO-week snapshot for the given target date using current MealPlan rows.
  #
  # @param target_date [Date] reference date inside the ISO week to archive
  # @param source [String] origin of the update ("manual", "ai_copilot", or "restore")
  # @param notes [String, nil] optional descriptive note
  # @return [MealPlanHistory] the persisted weekly history record
  def self.record_current_week!(target_date: Date.current, source: "manual", notes: nil)
    date = target_date.to_date
    iso_year = date.cwyear
    iso_week = date.cweek
    week_start = date.beginning_of_week(:monday)
    week_end = date.end_of_week(:monday)

    plans_by_day = MealPlan.includes(:lunch_dish, :dinner_dish).index_by(&:day_of_week)
    snapshot = MealPlan::DAYS_OF_WEEK.map do |day_name|
      plan = plans_by_day[day_name]
      {
        "day" => day_name,
        "lunch_dish_id" => plan&.lunch_dish_id,
        "lunch_dish_name" => plan&.lunch_dish&.name,
        "dinner_dish_id" => plan&.dinner_dish_id,
        "dinner_dish_name" => plan&.dinner_dish&.name
      }
    end

    history = find_or_initialize_by(year: iso_year, week_number: iso_week)
    history.assign_attributes(
      week_start_date: week_start,
      week_end_date: week_end,
      plan_snapshot: snapshot,
      source: SOURCES.include?(source.to_s) ? source.to_s : "manual"
    )
    history.notes = notes if notes.present?
    history.save!
    history
  end

  # Restores this weekly snapshot onto the active Monday-Sunday MealPlan records.
  # Dishes missing from the catalog by ID are looked up case-insensitively by saved name,
  # or skipped cleanly if deleted.
  #
  # @return [Hash] summary containing :restored_slots [Integer] and :skipped_names [Array<String>]
  def restore_to_calendar!
    dishes_by_id = Dish.all.index_by(&:id)
    dishes_by_lower_name = Dish.all.index_by { |d| d.name.strip.downcase }
    restored_slots = 0
    skipped_names = []

    ActiveRecord::Base.transaction do
      MealPlan::DAYS_OF_WEEK.each do |day_name|
        entry = Array(plan_snapshot).find { |item| (item["day"] || item[:day]).to_s == day_name } || {}
        meal_plan = MealPlan.find_or_create_by!(day_of_week: day_name)

        lunch_dish, lunch_skipped = resolve_snapshot_dish(
          entry["lunch_dish_id"] || entry[:lunch_dish_id],
          entry["lunch_dish_name"] || entry[:lunch_dish_name],
          dishes_by_id,
          dishes_by_lower_name
        )
        dinner_dish, dinner_skipped = resolve_snapshot_dish(
          entry["dinner_dish_id"] || entry[:dinner_dish_id],
          entry["dinner_dish_name"] || entry[:dinner_dish_name],
          dishes_by_id,
          dishes_by_lower_name
        )

        restored_slots += 1 if lunch_dish.present?
        restored_slots += 1 if dinner_dish.present?
        skipped_names << lunch_skipped if lunch_skipped.present?
        skipped_names << dinner_skipped if dinner_skipped.present?

        meal_plan.update!(lunch_dish: lunch_dish, dinner_dish: dinner_dish)
      end

      self.class.record_current_week!(target_date: Date.current, source: "restore")
    end

    { restored_slots: restored_slots, skipped_names: skipped_names.uniq }
  end

  private

  # Resolves a dish from snapshot metadata using ID first, then lowercase name fallback.
  #
  # @param dish_id [Integer, String, nil]
  # @param dish_name [String, nil]
  # @param dishes_by_id [Hash{Integer => Dish}]
  # @param dishes_by_lower_name [Hash{String => Dish}]
  # @return [Array(Dish, nil)] matched dish and optional skipped dish name
  def resolve_snapshot_dish(dish_id, dish_name, dishes_by_id, dishes_by_lower_name)
    cleaned_name = dish_name.to_s.strip
    return [ nil, nil ] if dish_id.blank? && cleaned_name.blank?

    matched = dishes_by_id[dish_id.to_i] if dish_id.present?
    matched ||= dishes_by_lower_name[cleaned_name.downcase] if cleaned_name.present?

    if matched
      [ matched, nil ]
    else
      [ nil, cleaned_name.presence ]
    end
  end
end
