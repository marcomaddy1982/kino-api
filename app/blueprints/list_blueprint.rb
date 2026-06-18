class ListBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :is_favourite, :created_at
end
