class ListItem < ApplicationRecord
  belongs_to :list

  validates :tmdb_movie_id, presence: true, uniqueness: { scope: :list_id }
end
