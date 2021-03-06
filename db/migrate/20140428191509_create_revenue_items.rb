class CreateRevenueItems < ActiveRecord::Migration
  def change
    create_table :revenue_items do |t|
      t.integer :project_id, null: false
      t.integer :allocation_id
      t.integer :office_id, null: false
      t.integer :person_id, null: false
      t.string  :role, null: false
      t.date    :day, null: false
      t.boolean :provisional, default: false
      t.decimal :amount, scale: 2, precision: 10, default: 0.0
      t.hstore  :details
      t.timestamps
    end

    add_index :revenue_items, %i{day office_id project_id allocation_id person_id role provisional}, name: 'index_all_the_things', unique: true
  end
end
