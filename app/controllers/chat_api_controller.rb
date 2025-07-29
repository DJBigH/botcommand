# app/controllers/chat_api_controller.rb
class ChatApiController < ApplicationController
  skip_before_action :verify_authenticity_token  # tắt CSRF cho API

  require 'net/http'
  require 'uri'
  require 'json'

  def message
    bot_identifier = params[:bot_identifier]
    message = params[:message]
    sender = params[:sender] || 'guest'

    bot = Bot.find_by(bot_identifier: bot_identifier)
    unless bot
      render json: { error: "Bot không tồn tại" }, status: :not_found and return
    end

    rasa_uri = URI("http://localhost:#{bot.port}/webhooks/rest/webhook")
    http = Net::HTTP.new(rasa_uri.host, rasa_uri.port)
    req = Net::HTTP::Post.new(rasa_uri.path, { 'Content-Type' => 'application/json' })

    req.body = {
      sender: sender,
      message: message
    }.to_json

    begin
      res = http.request(req)
      render json: JSON.parse(res.body)
    rescue => e
      render json: { error: "Lỗi khi gọi Rasa: #{e.message}" }, status: 500
    end
  end
end
