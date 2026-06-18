class ListItemBlueprint < Blueprinter::Base
  identifier :id

  fields :tmdb_movie_id, :created_at
end
