class BotsController < ApplicationController
  require 'fileutils'
  require 'open3'

  before_action :set_bot, only: [:show, :train, :add_prompt]

  def index
    @bots = Bot.all
  end

  def new
    @bot = Bot.new
  end

  def create
    @bot = Bot.new(bot_params)

    if @bot.save
      bot_name_folder = @bot.name.parameterize.underscore
      bot_dir = Rails.root.join('rasa_projects', bot_name_folder)

      FileUtils.mkdir_p(bot_dir)

      activate_path = "/home/bigk/rasa-env/bin/activate"

      bash_command = <<~BASH
        cd "#{bot_dir}" && \
        source "#{activate_path}" && \
        rasa init --no-prompt
      BASH

      result = system("bash", "-c", bash_command)

      if result
        @bot.update!(path: bot_dir.to_s)
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
    update_stories_file(@bot)  # Cập nhật stories
    update_rules_file(@bot)    # Cập nhật rules
    redirect_to bot_path(@bot), notice: "Thêm prompt thành công!"
  else
    redirect_to bot_path(@bot), alert: "Lỗi khi thêm prompt."
  end
  end


  def train
  generate_domain_file(@bot)
  train_bot(@bot.path)
  redirect_to bot_path(@bot), notice: "Bot traning thành công!"
  end


  private

  def set_bot
    @bot = Bot.find(params[:id])
  end

  def bot_params
    params.require(:bot).permit(:name)
  end

  def prompt_params
    params.require(:prompt).permit(:question, :answer)
  end

  # Cập nhật hoặc thêm intent mới vào nlu.yml (không ghi đè file)
  def update_nlu_file(bot, new_prompt)

  nlu_path = File.join(bot.path, 'data', 'nlu.yml')
  FileUtils.mkdir_p(File.dirname(nlu_path)) unless Dir.exist?(File.dirname(nlu_path))

  nlu_data = if File.exist?(nlu_path)
               YAML.load_file(nlu_path)
             else
               { 'version' => '3.1', 'nlu' => [] }
             end

  intent_name = "custom_intent_#{new_prompt.id}"
  example_line = "- #{new_prompt.question.strip}"

  existing_intent = nlu_data['nlu'].find { |intent| intent['intent'] == intent_name }

  if existing_intent
    examples_lines = existing_intent['examples'].split("\n").map(&:strip)
    unless examples_lines.include?(example_line)
      examples_lines << example_line
      existing_intent['examples'] = examples_lines.join("\n")
    end
  else
    nlu_data['nlu'] << {
      'intent' => intent_name,
      'examples' => "#{example_line}\n"
    }
  end

  # Khi ghi YAML, bắt buộc giữ định dạng block literal cho 'examples'
  # Tuy nhiên, YAML.dump không giữ định dạng block literal,
  # nên bạn cần ghi thủ công hoặc dùng gem hỗ trợ.

  # Cách đơn giản: ghi thủ công
  File.open(nlu_path, 'w') do |file|
    file.puts "version: '3.1'"
    file.puts "nlu:"
    nlu_data['nlu'].each do |intent|
      file.puts "- intent: #{intent['intent']}"
      file.puts "  examples: |"
      intent['examples'].split("\n").each do |line|
        file.puts "    #{line}"
      end
    end
  end
  end



  def generate_domain_file(bot)
  domain_path = File.join(bot.path, 'domain.yml')

  # Đọc domain.yml cũ nếu có, nếu không có thì khởi tạo mặc định
  domain_data = if File.exist?(domain_path)
                  YAML.load_file(domain_path) || {}
                else
                  {}
                end

  domain_data['version'] ||= '3.0'
  domain_data['intents'] ||= []
  domain_data['responses'] ||= {}

  # Thêm intents từ prompt, tránh trùng lặp
  bot.prompts.each do |p|
    intent_name = "custom_intent_#{p.id}"
    domain_data['intents'] << intent_name unless domain_data['intents'].include?(intent_name)

    # Thêm response tương ứng
    response_name = "utter_#{intent_name}"
    unless domain_data['responses'].key?(response_name)
      domain_data['responses'][response_name] = [{ 'text' => p.answer.gsub('"', '\"') }]
    end
  end

  # Giữ nguyên các phần khác như entities, session_config nếu có

  File.write(domain_path, domain_data.to_yaml)
  end


  # Nếu bạn muốn reset toàn bộ nlu.yml theo prompt hiện tại (dùng khi train lại)
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

    nlu_file_path = File.join(bot.path, 'data', 'nlu.yml')
    FileUtils.mkdir_p(File.dirname(nlu_file_path))
    File.write(nlu_file_path, content)
  end

  def train_bot(path)
    activate_path = "/home/bigk/rasa-env/bin/activate"
    bash_command = <<~BASH
      cd "#{path}" && \
      source "#{activate_path}" && \
      rasa train
    BASH
    system("bash", "-c", bash_command)
  end


  def update_stories_file(bot)
  stories_path = File.join(bot.path, 'data', 'stories.yml')
  FileUtils.mkdir_p(File.dirname(stories_path)) unless Dir.exist?(File.dirname(stories_path))

  existing_stories_data = if File.exist?(stories_path)
                           YAML.load_file(stories_path) || {}
                         else
                           {}
                         end

  existing_stories = existing_stories_data['stories'] || []

  new_stories = bot.prompts.map do |p|
    {
      'story' => "story_custom_intent_#{p.id}",
      'steps' => [
        { 'intent' => "custom_intent_#{p.id}" },
        { 'action' => "utter_custom_intent_#{p.id}" }
      ]
    }
  end

  existing_story_names = existing_stories.map { |s| s['story'] }
  combined_stories = existing_stories + new_stories.reject { |s| existing_story_names.include?(s['story']) }

  stories_data = {
    'version' => existing_stories_data['version'] || '3.1',
    'stories' => combined_stories
  }

  File.write(stories_path, stories_data.to_yaml)
  end

  def update_rules_file(bot)
  rules_path = File.join(bot.path, 'data', 'rules.yml')
  FileUtils.mkdir_p(File.dirname(rules_path)) unless Dir.exist?(File.dirname(rules_path))

  existing_rules_data = if File.exist?(rules_path)
                         YAML.load_file(rules_path) || {}
                       else
                         {}
                       end

  existing_rules = existing_rules_data['rules'] || []

  new_rules = bot.prompts.map do |p|
    {
      'rule' => "rule_custom_intent_#{p.id}",
      'steps' => [
        { 'intent' => "custom_intent_#{p.id}" },
        { 'action' => "utter_custom_intent_#{p.id}" }
      ]
    }
  end

  existing_rule_names = existing_rules.map { |r| r['rule'] }
  combined_rules = existing_rules + new_rules.reject { |r| existing_rule_names.include?(r['rule']) }

  rules_data = {
    'version' => existing_rules_data['version'] || '3.1',
    'rules' => combined_rules
  }

  File.write(rules_path, rules_data.to_yaml)
  end

end
