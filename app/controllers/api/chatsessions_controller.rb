class Api::ChatsessionsController < ApplicationController
   protect_from_forgery with: :null_session

    def create
      bot = Bot.find_by(bot_identifier: params[:bot_identifier])
      return render json: { error: "Bot không tồn tại" }, status: :not_found unless bot

      session = ChatSession.new(
        bot: bot,
        name: params[:name],
        phone: params[:phone],
        active: true,
        admin_joined: false
      )

      if session.save
        render json: { id: session.id }, status: :created
      else
        render json: { error: session.errors.full_messages }, status: :unprocessable_entity
      end
    end
end
