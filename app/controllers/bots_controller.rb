class BotsController < ApplicationController
  require "fileutils"
  require "open3"
  require "net/http"
  require "uri"
  require "json"


  before_action :set_bot, only: [ :show, :train, :add_prompt, :chat, :run, :stop ]

  def index
  @bots = Bot.paginate(page: params[:page], per_page: 5)
  end


  def new
    @bot = Bot.new
  end

  def create
  @bot = Bot.new(bot_params.merge(status: "not_started"))
  @bot.port = next_available_port
  @bot.action_port = next_available_actions_port

  if @bot.save
    bot_name_folder = @bot.name.parameterize.underscore
    bot_dir = Rails.root.join("rasa_projects", bot_name_folder)

    FileUtils.mkdir_p(bot_dir)

    activate_path = "/home/chung/rasa-env/bin/activate"

    bash_command = <<~BASH
      cd "#{bot_dir}" && \
      source "#{activate_path}" && \
      rasa init --no-prompt
    BASH

    result = system("bash", "-c", bash_command)

    if result
      @bot.update!(path: bot_dir.to_s)

      clear_sample_data(bot_dir)
      generate_endpoints_file(@bot)

      redirect_to bot_path(@bot), notice: "Tạo bot thành công!"
    else
      @bot.destroy
      flash[:alert] = "Tạo bot thất bại. Vui lòng liên hệ với quản trị viên!"
      render :new
    end
  else
    render :new
  end
  end



  def show
    @prompt = Prompt.new
    @prompts = @bot.prompts
  end

  def add_prompt
  @prompt = @bot.prompts.new(prompt_params)
  if @prompt.save
    update_nlu_file(@bot, @prompt)
    generate_domain_file(@bot)
    update_stories_file(@bot)
    update_rules_file(@bot)
    redirect_to bot_path(@bot), notice: "Thêm prompt thành công!"
  else
    redirect_to bot_path(@bot), alert: "Lỗi khi thêm prompt."
  end
  end


  def train
  @bot.update(status: "training")

  generate_domain_file(@bot)
  train_bot(@bot.path)
  stop_bot(@bot.port, @bot.action_port)
  @bot.update(status: "not_started")

  redirect_to bot_path(@bot), notice: "Train thành công! Bot đã sẵn sàng để khởi động."
  end






  def run
  @bot.update(status: "starting")
  run_bot(@bot.path, @bot.port, @bot.action_port)

  Thread.new do
    bot = Bot.find(@bot.id)
    if wait_for_rasa_ready(bot.port)
      bot.update(status: "running")
    else
      bot.update(status: "not_started")
    end
  end

  redirect_to bots_path, notice: "Đang khởi động bot..."
  end


  def stop
  Thread.new do
    success = stop_bot(@bot.port, @bot.action_port)
    @bot.update(status: success ? "not_started" : "error")
  end

  redirect_to bots_path, notice: "Đang dừng bot..."
  end

  private

  def set_bot
    @bot = Bot.find(params[:id])
  end

  def bot_params
  params.require(:bot).permit(:name, :status, :bot_identifier)
  end


  def prompt_params
    params.require(:prompt).permit(:question, :answer)
  end

  # Cập nhật hoặc thêm intent mới vào nlu.yml (không ghi đè file)
  def update_nlu_file(bot, new_prompt)
  nlu_path = File.join(bot.path, "data", "nlu.yml")
  FileUtils.mkdir_p(File.dirname(nlu_path)) unless Dir.exist?(File.dirname(nlu_path))

  nlu_data = if File.exist?(nlu_path)
             loaded = YAML.load_file(nlu_path)
             loaded.is_a?(Hash) ? loaded : { "version" => "3.1", "nlu" => [] }
  else
             { "version" => "3.1", "nlu" => [] }
  end


  intent_name = "custom_intent_#{new_prompt.id}"
  example_line = "- #{new_prompt.question.strip}"

  existing_intent = nlu_data["nlu"].find { |intent| intent["intent"] == intent_name }

  if existing_intent
    examples_lines = existing_intent["examples"].split("\n").map(&:strip)
    unless examples_lines.include?(example_line)
      examples_lines << example_line
      existing_intent["examples"] = examples_lines.join("\n")
    end
  else
    nlu_data["nlu"] << {
      "intent" => intent_name,
      "examples" => "#{example_line}\n"
    }
  end

  File.open(nlu_path, "w") do |file|
    file.puts "version: '3.1'"
    file.puts "nlu:"
    nlu_data["nlu"].each do |intent|
      file.puts "- intent: #{intent['intent']}"
      file.puts "  examples: |"
      intent["examples"].split("\n").each do |line|
        file.puts "    #{line}"
      end
    end
  end
  end



  def generate_domain_file(bot)
  domain_path = File.join(bot.path, "domain.yml")

  # Đọc domain.yml cũ nếu có, nếu không có thì khởi tạo mặc định
  domain_data = if File.exist?(domain_path)
                loaded = YAML.load_file(domain_path)
                loaded.is_a?(Hash) ? loaded : {}
  else
                {}
  end


  domain_data["version"] ||= "3.1"
  domain_data["intents"] ||= []
  domain_data["responses"] ||= {}

  # Thêm intents từ prompt, tránh trùng lặp
  bot.prompts.each do |p|
    intent_name = "custom_intent_#{p.id}"
    domain_data["intents"] << intent_name unless domain_data["intents"].include?(intent_name)

    # Thêm response tương ứng
    response_name = "utter_#{intent_name}"
    unless domain_data["responses"].key?(response_name)
      domain_data["responses"][response_name] = [ { "text" => p.answer.gsub('"', '\"') } ]
    end
  end

  # Giữ nguyên các phần khác như entities, session_config nếu có

  File.write(domain_path, domain_data.to_yaml)
  end


  def generate_training_data(bot)
    content = <<~YAML
      version: "3.0"
      nlu:
    YAML

    bot.prompts.each do |p|
      content += <<~YAML
        - intent: custom_intent_#{p.id}
          examples: |
            - #{p.question.strip}
      YAML
    end

    nlu_file_path = File.join(bot.path, "data", "nlu.yml")
    FileUtils.mkdir_p(File.dirname(nlu_file_path))
    File.write(nlu_file_path, content)
  end

  def train_bot(path)
  activate_path = "/home/chung/rasa-env/bin/activate"

  bash_command = <<~BASH
    cd "#{path}" && \
    source "#{activate_path}" && \
    rasa train
  BASH

  Rails.logger.info "[TRAINING] Đang train bot tại #{path}"
  system("bash", "-c", bash_command)
  end



  def run_bot(path, port, action_port)
  activate_path = "/home/chung/rasa-env/bin/activate"

  # Run action server trước
  action_cmd = <<~BASH
    cd "#{path}" && \
    source "#{activate_path}" && \
    rasa run actions --port #{action_port} --debug
  BASH

  fork do
    system("bash", "-c", action_cmd)
  end

  sleep 3 # chờ action server chạy ổn định

  # Run rasa server
  rasa_cmd = <<~BASH
    cd "#{path}" && \
    source "#{activate_path}" && \
    rasa run --enable-api --cors "*" --port #{port} --endpoints endpoints.yml --debug
  BASH

  fork do
    system("bash", "-c", rasa_cmd)
  end
  end





  def wait_for_rasa_ready(port)
  20.times do |i|   # tăng lên 20 lần
    sleep 3         # mỗi lần chờ 3 giây → tổng 60 giây
    begin
      uri = URI("http://localhost:#{port}/status")
      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)

        if data["model_file"].present?
          Rails.logger.info "[RASA READY] Sẵn sàng tại lần thử #{i + 1}"
          return true
        end
      end
    rescue => e
      Rails.logger.warn "[RASA CHECK] Thử #{i + 1} bị lỗi: #{e.message}"
    end
  end

  Rails.logger.error "[RASA TIMEOUT] Rasa không phản hồi sau 60 giây"
  false
  end


  def stop_bot(bot_port, action_port)
  [ bot_port, action_port ].each do |port|
    pid = `lsof -i:#{port} -t`.strip
    next if pid.blank?

    begin
      # Gửi tín hiệu dừng nhẹ
      Process.kill("TERM", pid.to_i)
      Rails.logger.info "[STOP BOT] Đã gửi SIGTERM đến PID #{pid} (port #{port})"

      # Chờ quá trình dừng hẳn (timeout 5s)
      10.times do
        sleep 0.5
        break unless system("kill -0 #{pid}") # nếu không còn tồn tại
      end

      # Nếu chưa dừng → kill -9
      if system("kill -0 #{pid}")
        Process.kill("KILL", pid.to_i)
        Rails.logger.warn "[STOP BOT] Buộc kill PID #{pid} vì không tự dừng"
      end
    rescue => e
      Rails.logger.error "[STOP BOT ERROR] #{e.message}"
    end
  end
  end

  def next_available_port(start_port = 5005)
  used_ports = Bot.pluck(:port)
  port = start_port

  while used_ports.include?(port)
    port += 1
  end

  port
  end

 def next_available_actions_port(start_actions_port = 5055)
  used_action_ports = Bot.pluck(:action_port)
  action_port = start_actions_port

  while used_action_ports.include?(action_port)
    action_port += 1
  end

  action_port
  end


  def generate_endpoints_file(bot)
    content = <<~YAML
      action_endpoint:
        url: "http://localhost:#{bot.action_port}/webhook"
    YAML

    File.write(File.join(bot.path, "endpoints.yml"), content)
  end


  def update_stories_file(bot)
  stories_path = File.join(bot.path, "data", "stories.yml")
  FileUtils.mkdir_p(File.dirname(stories_path)) unless Dir.exist?(File.dirname(stories_path))

  existing_stories_data = if File.exist?(stories_path)
                           YAML.load_file(stories_path) || {}
  else
                           {}
  end

  existing_stories = existing_stories_data["stories"] || []

  new_stories = bot.prompts.map do |p|
    {
      "story" => "story_custom_intent_#{p.id}",
      "steps" => [
        { "intent" => "custom_intent_#{p.id}" },
        { "action" => "utter_custom_intent_#{p.id}" }
      ]
    }
  end

  existing_story_names = existing_stories.map { |s| s["story"] }
  combined_stories = existing_stories + new_stories.reject { |s| existing_story_names.include?(s["story"]) }

  stories_data = {
    "version" => existing_stories_data["version"] || "3.1",
    "stories" => combined_stories
  }

  File.write(stories_path, stories_data.to_yaml)
  end

  def update_rules_file(bot)
  rules_path = File.join(bot.path, "data", "rules.yml")
  FileUtils.mkdir_p(File.dirname(rules_path)) unless Dir.exist?(File.dirname(rules_path))

  existing_rules_data = if File.exist?(rules_path)
                         YAML.load_file(rules_path) || {}
  else
                         {}
  end

  existing_rules = existing_rules_data["rules"] || []

  new_rules = bot.prompts.map do |p|
    {
      "rule" => "rule_custom_intent_#{p.id}",
      "steps" => [
        { "intent" => "custom_intent_#{p.id}" },
        { "action" => "utter_custom_intent_#{p.id}" }
      ]
    }
  end

  existing_rule_names = existing_rules.map { |r| r["rule"] }
  combined_rules = existing_rules + new_rules.reject { |r| existing_rule_names.include?(r["rule"]) }

  rules_data = {
    "version" => existing_rules_data["version"] || "3.1",
    "rules" => combined_rules
  }

  File.write(rules_path, rules_data.to_yaml)
  end


  def chat_response
  message = params[:message]
  Rails.logger.info "ID nhận được: #{params[:id]}"
  @bot = Bot.find_by(id: params[:id])
  if @bot.nil?
    Rails.logger.warn "Không tìm thấy bot với ID #{params[:id]}"
    redirect_to bots_path, alert: "Không tìm thấy bot!"
  end

  unless @bot
    render json: { error: "Không tìm thấy bot!" }, status: :not_found and return
  end

  Rails.logger.info "Bot tìm thấy: #{@bot.inspect}"

  port = @bot.port

  uri = URI("http://localhost:#{port}/webhooks/rest/webhook")
  http = Net::HTTP.new(uri.host, uri.port)
  req = Net::HTTP::Post.new(uri.path, { 'Content-Type': "application/json" })

  req.body = {
    sender: "admin", # người gửi mặc định
    message: message
  }.to_json

  begin
    response = http.request(req)
    body = JSON.parse(response.body)
    messages = body.map { |m| m["text"] }.compact
    render json: { replies: messages }
  rescue => e
    Rails.logger.error "Lỗi khi gọi Rasa: #{e.message}"
    render json: { error: "Không thể kết nối tới Rasa" }, status: :bad_gateway
  end
  end

  def clear_sample_data(bot_path)
  %w[data/nlu.yml data/rules.yml data/stories.yml domain.yml].each do |rel_path|
    full_path = File.join(bot_path, rel_path)
    File.write(full_path, "") if File.exist?(full_path)
  end
  end


  def chat
  @bot = Bot.find_by(id: params[:id])

  unless @bot
    Rails.logger.debug "Không tìm thấy bot với ID: #{params[:id]}"
    redirect_to bots_path, alert: "Không tìm thấy bot"
  end
  end
end
