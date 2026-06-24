class ListItemBlueprint < Blueprinter::Base
  field :id do |item, options|
    options[:tmdb_details]&.dig(item.tmdb_movie_id, "id")
  end

  field :title do |item, options|
    options[:tmdb_details]&.dig(item.tmdb_movie_id, "title")
  end

  field :poster_path do |item, options|
    options[:tmdb_details]&.dig(item.tmdb_movie_id, "poster_path")
  end

  field :vote_average do |item, options|
    options[:tmdb_details]&.dig(item.tmdb_movie_id, "vote_average")
  end

  field :release_date do |item, options|
    options[:tmdb_details]&.dig(item.tmdb_movie_id, "release_date")
  end
end
