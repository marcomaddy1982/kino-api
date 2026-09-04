module V1
  class CalendarEntriesController < ::ApplicationController
    def index
      year, month = parse_month(params[:month])
      entries_by_date = CalendarService.entries_for_month(current_user, year: year, month: month)

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

    def parse_month(month_param)
      date = month_param.present? ? Date.parse("#{month_param}-01") : Date.current
      [ date.year, date.month ]
    rescue Date::Error
      raise KinoErrors::BadRequestError
    end
  end
end
