require "rails_helper"

RSpec.describe EnvResolver do
  describe ".fetch" do
    it "returns the ENV value when set" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("SAMPLE_TEST_KEY").and_return("secret-value")

      expect(described_class.fetch("SAMPLE_TEST_KEY")).to eq("secret-value")
    end

    it "returns an empty string when unset outside development" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("MISSING_TEST_KEY").and_return(nil)

      expect(described_class.fetch("MISSING_TEST_KEY")).to eq("")
    end
  end
end
