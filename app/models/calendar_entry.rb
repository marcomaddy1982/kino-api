class CalendarEntry < ApplicationRecord
  belongs_to :user

  validates :tmdb_movie_id, presence: true
  validates :scheduled_on, presence: true
  validates :title, presence: true
  validates :tmdb_movie_id, uniqueness: { scope: [ :user_id, :scheduled_on ], message: "already added on this date" }
end
