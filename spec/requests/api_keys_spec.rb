require 'rails_helper'

RSpec.describe "ApiKeys UI Management", type: :request do
  describe "GET /api_keys" do
    it "renders the key manager index successfully" do
      get api_keys_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t('api_keys.index.title'))
    end
  end

  describe "POST /api_keys" do
    context "with valid parameters" do
      it "creates a new api key, redirects, and displays success notification" do
        expect {
          post api_keys_path, params: { api_key: { name: "Home Assistant" } }
        }.to change(ApiKey, :count).by(1)

        expect(response).to redirect_to(api_keys_path)
        follow_redirect!
        expect(response.body).to include(I18n.t('api_keys.controller.created'))
        expect(flash[:plain_token]).to be_present
        expect(flash[:plain_token]).to start_with('dmeal_live_')
      end
    end

    context "with invalid parameters" do
      it "does not create a key and renders errors" do
        expect {
          post api_keys_path, params: { api_key: { name: "" } }
        }.not_to change(ApiKey, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /api_keys/:id" do
    let!(:api_key) { ApiKey.create!(name: "Gemini App") }

    it "toggles the active status of the key" do
      expect(api_key.active).to be true
      
      patch api_key_path(api_key), params: { api_key: { active: false } }
      expect(response).to redirect_to(api_keys_path)
      
      api_key.reload
      expect(api_key.active).to be false
    end
  end

  describe "DELETE /api_keys/:id" do
    let!(:api_key) { ApiKey.create!(name: "Temporary Key") }

    it "revokes/destroys the api key and redirects with notification" do
      expect {
        delete api_key_path(api_key)
      }.to change(ApiKey, :count).by(-1)

      expect(response).to redirect_to(api_keys_path)
      follow_redirect!
      expect(response.body).to include(I18n.t('api_keys.controller.revoked'))
    end
  end
end
