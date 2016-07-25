class CreateSubventions < ActiveRecord::Migration
  def change
    create_table :subventions do |t|
      t.string :libelle
      t.float :montant
      t.belongs_to :projet, index: true, foreign_key: true
    end
  end
end
