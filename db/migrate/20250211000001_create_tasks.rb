class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :title
      t.text :description
      t.integer :status, null: false, default: 0
      t.string :url, null: false
      t.jsonb :result, default: {}
      t.text :error_message
      t.bigint :user_id, null: false
      t.string :user_email
      t.datetime :completed_at

      t.timestamps
    end

    add_index :tasks, :user_id
    add_index :tasks, :status
  end
end
