class ListItemBlueprint < Blueprinter::Base
  identifier :id

  fields :tmdb_movie_id, :created_at

  field :title do |item, options|
    options[:tmdb_details]&.dig(item.tmdb_movie_id, "title")
  end

  field :poster_path do |item, options|
    options[:tmdb_details]&.dig(item.tmdb_movie_id, "poster_path")
  end
end
