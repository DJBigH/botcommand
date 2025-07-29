class ChatController < ApplicationController
    after_action :allow_iframe, only: [:embed_chat]

  def embed_chat
  bot_identifier = params[:bot_identifier]

  @bot = Bot.find_by(bot_identifier: bot_identifier)

  if @bot
    @bot_api_url = "http://localhost:#{@bot.port}/webhooks/rest/webhook"
  else
    render plain: "Không tìm thấy bot", status: :not_found
  end
  end

  private
  def allow_iframe
    response.headers.delete('X-Frame-Options')
    response.headers['Content-Security-Policy'] = "frame-ancestors *"
  end
end
