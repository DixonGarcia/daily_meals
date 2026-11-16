require 'rails_helper'

RSpec.describe GeminiClient do
  describe "#generate_plan_response" do
    it "raises ConfigurationError when GEMINI_API_KEY is blank" do
      client = described_class.new(api_key: "")
      expect {
        client.generate_plan_response(system_instruction: "System", messages: [{ role: "user", content: "Hola" }])
      }.to raise_error(GeminiClient::ConfigurationError)
    end

    it "parses the structured JSON response from Gemini API" do
      fake_body = {
        candidates: [
          {
            content: {
              parts: [
                {
                  text: {
                    reply: "Aquí tienes tu menú de lunes a viernes.",
                    meal_plan: [
                      { day: "Monday", lunch_dish_id: 1, dinner_dish_id: 2 }
                    ]
                  }.to_json
                }
              ]
            }
          }
        ]
      }.to_json

      fake_response = instance_double(Net::HTTPOK, is_a?: true, body: fake_body, code: "200")
      allow(fake_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      http_double = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:use_ssl=)
      allow(http_double).to receive(:open_timeout=)
      allow(http_double).to receive(:read_timeout=)
      allow(http_double).to receive(:request).and_return(fake_response)

      client = described_class.new(api_key: "test-gemini-key", model: "gemini-2.5-flash")
      result = client.generate_plan_response(
        system_instruction: "Eres un asistente culinario.",
        messages: [{ role: "user", content: "Planifica lunes" }]
      )

      expect(result[:reply]).to eq("Aquí tienes tu menú de lunes a viernes.")
      expect(result[:meal_plan]).to eq([{ "day" => "Monday", "lunch_dish_id" => 1, "dinner_dish_id" => 2 }])
    end

    it "raises ApiError when the HTTP response is unsuccessful" do
      fake_response = instance_double(Net::HTTPBadRequest, body: '{"error":"invalid"}', code: "400")
      allow(fake_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)

      http_double = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:use_ssl=)
      allow(http_double).to receive(:open_timeout=)
      allow(http_double).to receive(:read_timeout=)
      allow(http_double).to receive(:request).and_return(fake_response)

      client = described_class.new(api_key: "test-gemini-key")
      expect {
        client.generate_plan_response(system_instruction: "Sys", messages: [{ role: "user", content: "Hola" }])
      }.to raise_error(GeminiClient::ApiError)
    end

    it "automatically falls back to DEFAULT_MODEL when a custom model returns HTTP 404" do
      not_found_response = instance_double(Net::HTTPNotFound, body: '{"error":{"code":404}}', code: "404")
      allow(not_found_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)

      ok_body = {
        candidates: [
          {
            content: {
              parts: [
                {
                  text: {
                    reply: "Respuesta usando modelo de respaldo.",
                    meal_plan: []
                  }.to_json
                }
              ]
            }
          }
        ]
      }.to_json
      ok_response = instance_double(Net::HTTPOK, body: ok_body, code: "200")
      allow(ok_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      http_double = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:use_ssl=)
      allow(http_double).to receive(:open_timeout=)
      allow(http_double).to receive(:read_timeout=)
      allow(http_double).to receive(:request).and_return(not_found_response, ok_response)

      client = described_class.new(api_key: "test-gemini-key", model: "gemini-legacy-404-model")
      result = client.generate_plan_response(system_instruction: "Sys", messages: [{ role: "user", content: "Hola" }])

      expect(result[:reply]).to eq("Respuesta usando modelo de respaldo.")
    end
  end

  describe "#suggest_dish_ingredients" do
    it "parses suggested category and ingredients from Gemini" do
      fake_body = {
        candidates: [
          {
            content: {
              parts: [
                {
                  text: {
                    category: "Lunch",
                    ingredients: [
                      { name: "Pechuga de pollo", supermarket_section: "Carnicería", suggested_quantity: "500g" },
                      { name: "Curry en polvo", supermarket_section: "Despensa", suggested_quantity: "2 cdas" }
                    ]
                  }.to_json
                }
              ]
            }
          }
        ]
      }.to_json

      fake_response = instance_double(Net::HTTPOK, body: fake_body, code: "200")
      allow(fake_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      http_double = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:use_ssl=)
      allow(http_double).to receive(:open_timeout=)
      allow(http_double).to receive(:read_timeout=)
      allow(http_double).to receive(:request).and_return(fake_response)

      client = described_class.new(api_key: "test-gemini-key")
      result = client.suggest_dish_ingredients(dish_name: "Pollo al curry", existing_ingredients: [])

      expect(result[:category]).to eq("Lunch")
      expect(result[:ingredients].size).to eq(2)
      expect(result[:ingredients].first["name"]).to eq("Pechuga de pollo")
    end
  end
end
