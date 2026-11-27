# Handles the dedicated interactive Shopping List view (/shopping_list).
# Accessible in read-only/client-interactive mode without login so all household members
# can check off items, filter by market stop, and copy lists to WhatsApp from mobile.
class ShoppingListsController < ApplicationController
  allow_guest_access only: :show

  # Default household servings count for the shopping list view when no cookie is stored.
  DEFAULT_HOUSEHOLD_SERVINGS = 2

  # GET /shopping_list
  # Renders the interactive shopping list grouped into weekly fresh stops and pantry staples.
  #
  # @return [void]
  def show
    @servings = resolve_servings
    @grouped_list = ShoppingListGenerator.new(servings: @servings).generate_grouped
    @fresh_sections = @grouped_list[:fresh]
    @pantry_sections = @grouped_list[:pantry]
    @fresh_count = @grouped_list[:fresh_count]
    @pantry_count = @grouped_list[:pantry_count]
    @total_count = @grouped_list[:total_count]
    @week_key = Time.zone.today.strftime("%G-W%V")
  end

  private

  # Resolves household servings from query parameter or persisted cookie, falling back safely.
  #
  # @return [Integer]
  def resolve_servings
    if params[:servings].present?
      requested = params[:servings].to_i
      if requested.between?(1, ShoppingListGenerator::MAX_SERVINGS)
        cookies[:shopping_servings] = {
          value: requested.to_s,
          expires: 60.days.from_now,
          same_site: :lax,
          secure: request.ssl?
        }
        return requested
      end
    end

    stored = cookies[:shopping_servings].to_i
    return stored if stored.between?(1, ShoppingListGenerator::MAX_SERVINGS)

    DEFAULT_HOUSEHOLD_SERVINGS
  end
end
