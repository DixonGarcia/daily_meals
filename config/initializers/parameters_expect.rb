# Backport of Rails 8 `params.expect` to Rails 7.2
class ActionController::Parameters
  # Expects parameters to have a specific structure and permits keys.
  #
  # @param filters [Symbol, String, Hash] parameter keys to expect.
  # @return [Object] the permitted parameters or the required value.
  def expect(filters)
    if filters.is_a?(Hash)
      key = filters.keys.first
      values = filters[key]
      require(key).permit(*values)
    else
      require(filters)
    end
  end
end
