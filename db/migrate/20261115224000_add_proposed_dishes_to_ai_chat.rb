class AddProposedDishesToAiChat < ActiveRecord::Migration[8.0]
  def change
    add_column :ai_chat_sessions, :proposed_dishes, :jsonb, null: false, default: []
    add_column :ai_chat_messages, :proposed_dishes, :jsonb, null: false, default: []
  end
end
