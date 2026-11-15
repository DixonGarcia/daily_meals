require 'rails_helper'

RSpec.describe "Sessions & Single-Owner Access Control", type: :request, unauthenticated: true do
  let(:master_password) { "super-secret-owner-key-2026" }

  around do |example|
    original_password = ENV["APP_ACCESS_PASSWORD"]
    ENV["APP_ACCESS_PASSWORD"] = master_password
    example.run
  ensure
    ENV["APP_ACCESS_PASSWORD"] = original_password
  end

  describe "Unauthenticated access protection" do
    it "redirects GET / to the login page with an alert" do
      get root_path
      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq(I18n.t("sessions.controller.unauthenticated"))
    end

    it "redirects GET /dishes to the login page" do
      get dishes_path
      expect(response).to redirect_to(new_session_path)
    end

    it "redirects GET /ingredients to the login page" do
      get ingredients_path
      expect(response).to redirect_to(new_session_path)
    end

    it "redirects GET /api_keys to the login page" do
      get api_keys_path
      expect(response).to redirect_to(new_session_path)
    end

    it "blocks unauthenticated mutations on PATCH /meal_plans/update_day" do
      patch update_day_meal_plans_path, params: { day_of_week: "Monday", lunch_dish_id: nil, dinner_dish_id: nil }
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "GET /session/new" do
    it "renders the login page successfully" do
      get new_session_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("sessions.new.title"))
      expect(response.body).to include(I18n.t("sessions.new.submit"))
    end
  end

  describe "POST /session" do
    context "with valid master password" do
      it "creates an encrypted session cookie and redirects to root" do
        post session_path, params: { password: master_password }
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq(I18n.t("sessions.controller.signed_in"))

        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("layout.logout"))
      end
    end

    context "with invalid password" do
      it "rejects login with 422 Unprocessable Content and shows alert" do
        post session_path, params: { password: "wrong-password" }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(I18n.t("sessions.controller.invalid_password"))

        get root_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when ENV['APP_ACCESS_PASSWORD'] is blank (fail-closed guard)" do
      it "denies login even if an empty or non-empty password is submitted" do
        ENV["APP_ACCESS_PASSWORD"] = ""
        post session_path, params: { password: "" }
        expect(response).to have_http_status(:unprocessable_content)

        post session_path, params: { password: "any-password" }
        expect(response).to have_http_status(:unprocessable_content)

        get root_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "Session revocation & logout" do
    it "logs out via DELETE /session and prevents subsequent access" do
      post session_path, params: { password: master_password }
      expect(response).to redirect_to(root_path)

      delete session_path
      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to eq(I18n.t("sessions.controller.signed_out"))

      get root_path
      expect(response).to redirect_to(new_session_path)
    end

    it "immediately invalidates existing session cookies if ENV['APP_ACCESS_PASSWORD'] is rotated" do
      post session_path, params: { password: master_password }
      get root_path
      expect(response).to have_http_status(:ok)

      ENV["APP_ACCESS_PASSWORD"] = "rotated-new-password-999"
      get root_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
