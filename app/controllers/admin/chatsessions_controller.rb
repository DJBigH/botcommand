class Admin::ChatsessionsController < ApplicationController
    protect_from_forgery with: :null_session

  def index
    @chat_sessions = ChatSession.includes(:bot).order(updated_at: :desc)
  end

  def show
  @chat_session = ChatSession.find(params[:id])
  @chat_session.update(admin_joined: 1)
  @chat_messages = @chat_session.chat_messages.order(:created_at)
  end

  def create
  bot = Bot.find_by(bot_identifier: params[:bot_identifier])
  return render json: { error: 'Bot không tồn tại' }, status: :not_found unless bot

  session = ChatSession.new(
    bot: bot,
    name: params[:name],
    phone: params[:phone],
    active: true,
    admin_joined: false
  )

  if session.save
    render json: { id: session.id }
  else
    render json: { error: session.errors.full_messages }, status: :unprocessable_entity
  end
  end

end
