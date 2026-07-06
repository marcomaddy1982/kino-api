module V1
  module Auth
    class SessionsController < ::ApplicationController
      skip_before_action :authenticate!

      def logout
        AuthService.logout(raw_token: params.require(:refresh_token))
        head :no_content
      end

      def refresh
        result = AuthService.refresh(raw_token: params.require(:refresh_token))
        render json: { accessToken: result[:access_token], refreshToken: result[:refresh_token] }, status: :ok
      end

      def login
        result = AuthService.login(
          email: params.require(:email),
          password: params.require(:password)
        )
        render json: serialize(result), status: :ok
      end

      def register
        result = AuthService.register(
          email: params.require(:email),
          password: params.require(:password),
          name: params.require(:name),
          phone_number: params[:phone_number]
        )
        render json: serialize(result), status: :created
      end

      private

      def serialize(result)
        {
          accessToken: result[:access_token],
          refreshToken: result[:refresh_token],
          user: {
            id: result[:user].id,
            email: result[:user].email,
            name: result[:user].name,
            phoneNumber: result[:user].phone_number
          }
        }
      end
    end
  end
end
