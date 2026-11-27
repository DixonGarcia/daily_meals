require 'rails_helper'

RSpec.describe "Settings, History & Integrations", type: :request do
  let!(:dish) { Dish.create!(name: 'Pabellón Criollo', categories: [ 'Lunch' ]) }

  describe "Navigation consolidation" do
    it "replaces API Keys navbar item with Configuración and moves Ingredientes to the dishes catalog" do
      get root_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t("layout.settings"))
      expect(response.body).to include(I18n.t("layout.shopping_list"))
      expect(response.body).not_to include("🔑 API Keys")
      expect(response.body).not_to include(I18n.t("layout.ingredients"))

      nav_links = response.body.scan(/<a [^>]*class="nav-link[^"]*"/).size
      expect(nav_links).to eq(4)

      get dishes_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t("dishes.index.ingredients_button"))
    end
  end

  describe "GET /settings" do
    it "renders the History tab by default" do
      MealPlanHistory.create!(
        year: 2026,
        week_number: 45,
        week_start_date: Date.new(2026, 11, 2),
        week_end_date: Date.new(2026, 11, 8),
        source: 'ai_copilot',
        plan_snapshot: [
          {
            'day' => 'Monday',
            'lunch_dish_id' => dish.id,
            'lunch_dish_name' => dish.name,
            'dinner_dish_id' => nil,
            'dinner_dish_name' => nil
          }
        ]
      )

      get settings_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t('settings.show.title'))
      expect(response.body).to include(I18n.t('settings.show.tabs.history'))
      expect(response.body).to include('Pabellón Criollo')
    end

    it "renders the Integrations tab with API Key manager when tab=integrations" do
      get settings_path(tab: 'integrations')
      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t('settings.show.integrations_intro'))
      expect(response.body).to include(I18n.t('api_keys.index.keys_title'))
    end
  end

  describe "History snapshot, restore & delete actions" do
    before do
      MealPlan::DAYS_OF_WEEK.each { |d| MealPlan.find_or_create_by!(day_of_week: d) }
      MealPlan.find_by!(day_of_week: 'Monday').update!(lunch_dish: dish)
    end

    it "captures a snapshot for current or next week via POST /meal_plan_histories/snapshot" do
      expect {
        post snapshot_meal_plan_histories_path, params: { week_offset: '0' }
      }.to change(MealPlanHistory, :count).by(1)

      expect(response).to redirect_to(settings_path(tab: 'history'))

      expect {
        post snapshot_meal_plan_histories_path, params: { week_offset: '1' }
      }.to change(MealPlanHistory, :count).by(1)
    end

    it "restores a saved snapshot onto the weekly calendar and redirects to root" do
      history = MealPlanHistory.record_current_week!(target_date: Date.new(2026, 11, 2), source: 'manual')
      MealPlan.find_by!(day_of_week: 'Monday').update!(lunch_dish: nil)

      post restore_meal_plan_history_path(history)
      expect(response).to redirect_to(root_path)
      expect(MealPlan.find_by!(day_of_week: 'Monday').lunch_dish).to eq(dish)
    end

    it "deletes a history record and redirects to settings history tab" do
      history = MealPlanHistory.record_current_week!(target_date: Date.new(2026, 11, 2), source: 'manual')

      expect {
        delete meal_plan_history_path(history)
      }.to change(MealPlanHistory, :count).by(-1)

      expect(response).to redirect_to(settings_path(tab: 'history'))
    end
  end

  describe "Integrations form redirect from Settings" do
    it "redirects back to /settings?tab=integrations when return_to=settings is sent" do
      post api_keys_path, params: { return_to: 'settings', api_key: { name: 'iPhone Atajos' } }
      expect(response).to redirect_to(settings_path(tab: 'integrations'))
      expect(flash[:plain_token]).to start_with('dmeal_live_')

      key = ApiKey.last
      patch api_key_path(key), params: { return_to: 'settings', api_key: { active: false } }
      expect(response).to redirect_to(settings_path(tab: 'integrations'))

      delete api_key_path(key), params: { return_to: 'settings' }
      expect(response).to redirect_to(settings_path(tab: 'integrations'))
    end
  end
end
