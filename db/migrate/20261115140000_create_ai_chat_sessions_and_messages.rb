class CreateAiChatSessionsAndMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_chat_sessions do |t|
      t.string :title, null: false
      t.jsonb :parameters, null: false, default: {}
      t.jsonb :proposed_plan, null: false, default: []
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    create_table :ai_chat_messages do |t|
      t.references :ai_chat_session, null: false, foreign_key: { on_delete: :cascade }
      t.string :role, null: false
      t.text :content, null: false
      t.jsonb :proposed_plan, null: false, default: []

      t.timestamps
    end
  end
end
