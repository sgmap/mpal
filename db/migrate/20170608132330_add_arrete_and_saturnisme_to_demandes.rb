class AddArreteAndSaturnismeToDemandes < ActiveRecord::Migration
  def change
    add_column :demandes, :arrete,     :boolean, null: false, default: false
    add_column :demandes, :saturnisme, :boolean, null: false, default: false
  end
end
