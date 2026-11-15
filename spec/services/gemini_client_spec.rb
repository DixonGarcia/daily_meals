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
  end
end
