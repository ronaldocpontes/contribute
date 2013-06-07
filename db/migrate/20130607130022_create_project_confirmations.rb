class CreateProjectConfirmations < ActiveRecord::Migration
  def up
    create_table :project_confirmations do |t|
      t.references :project
      t.string :payment_account_id

      t.timestamps
    end
    add_index :project_confirmations, :project_id

    Project.all.each do |p|
      if p.payment_account_id
        ProjectConfirmation.create(project_id: p.id, payment_account_id: p.payment_account_id)
      end
    end
    remove_column :projects, :payment_account_id
  end

  def down
    ActiveRecord::IrreversibleMigration
  end
end
