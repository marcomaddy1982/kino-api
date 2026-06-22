module V1
  class ListsController < ::ApplicationController
    before_action :set_list, only: [:destroy]

    def index
      ListService.find_or_create_favourites(current_user)
      lists = current_user.lists.order(created_at: :desc)
      render json: ListBlueprint.render(lists)
    end

    def create
      list = ListService.create(current_user, name: params.require(:name))
      render json: ListBlueprint.render(list), status: :created
    end

    def destroy
      ListService.destroy(@list)
      head :no_content
    end

    private

    def set_list
      @list = current_user.lists.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      raise KinoErrors::NotFoundError
    end
  end
end
