class ListBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :is_favourite, :created_at

  field :item_count do |list|
    list.list_items.size
  end
end
