class ListService
  class << self
    def find_or_create_favourites(user)
      user.lists.find_or_create_by!(is_favourite: true) do |list|
        list.name = "Favourites"
      end
    end

    def create(user, name:)
      user.lists.create!(name: name)
    end

    def destroy(list)
      raise KinoErrors::ForbiddenError if list.is_favourite?

      list.destroy!
    end
  end
end
