require 'rails_helper'

RSpec.describe ApiKey, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      key = ApiKey.new(name: 'Test Key', token_digest: 'digest_placeholder')
      expect(key).to be_valid
    end

    it 'is invalid without a name' do
      key = ApiKey.new(name: nil, token_digest: 'digest_placeholder')
      expect(key).not_to be_valid
    end

    it 'is invalid without a token_digest' do
      key = ApiKey.new(name: 'Test Key', token_digest: nil)
      allow(key).to receive(:generate_token).and_return(nil)
      expect(key).not_to be_valid
    end

    it 'enforces uniqueness of token_digest' do
      ApiKey.create!(name: 'First Key', token_digest: 'duplicate_digest')
      duplicate = ApiKey.new(name: 'Second Key', token_digest: 'duplicate_digest')
      expect(duplicate).not_to be_valid
    end
  end

  describe 'callbacks & custom token generation' do
    it 'generates a plain text token and stores a hashed digest upon creation' do
      # Note: We expect the class to have an accessor `token` or a way to access the generated plain token
      key = ApiKey.new(name: 'Assitant Key')
      expect(key.token_digest).to be_blank
      
      key.save!
      
      expect(key.token).to be_present
      expect(key.token).to start_with('dmeal_live_')
      expect(key.token_digest).to eq(Digest::SHA256.hexdigest(key.token))
    end
  end
end
