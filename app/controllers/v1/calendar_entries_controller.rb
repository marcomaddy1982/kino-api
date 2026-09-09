module V1
  class CalendarEntriesController < ::ApplicationController
    MAX_RANGE_DAYS = 92

    def index
      from = parse_date(params.require(:from))
      to   = parse_date(params.require(:to))
      raise KinoErrors::BadRequestError if to < from || (to - from).to_i > MAX_RANGE_DAYS

      entries_by_date = CalendarService.entries_in_range(current_user, from: from, to: to)

      result = entries_by_date.transform_keys(&:iso8601).transform_values do |entries|
        CalendarEntryBlueprint.render_as_hash(entries)
      end

      render json: result, status: :ok
    end

    def create
      entry = CalendarService.add(
        current_user,
        tmdb_movie_id: params.require(:tmdb_movie_id),
        scheduled_on: params.require(:scheduled_on)
      )
      render json: CalendarEntryBlueprint.render_as_hash(entry), status: :created
    end

    def update
      entry = CalendarService.reschedule(
        current_user,
        id: params[:id],
        scheduled_on: params.require(:scheduled_on)
      )
      render json: CalendarEntryBlueprint.render_as_hash(entry), status: :ok
    end

    def destroy
      CalendarService.remove(current_user, id: params[:id])
      head :no_content
    end

    def toggle_watched
      entry = CalendarService.toggle_watched(current_user, id: params[:id])
      render json: CalendarEntryBlueprint.render_as_hash(entry), status: :ok
    end

    private

    def parse_date(value)
      Date.iso8601(value)
    rescue ArgumentError, TypeError
      raise KinoErrors::BadRequestError
    end
  end
end
