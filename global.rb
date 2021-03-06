require 'fileutils'
require_relative 'event'
require_relative 'controller'
require_relative 'opening'
require_relative 'menu'
require_relative 'player'
require_relative 'world'
require_relative 'status'
require_relative 'stage'
require_relative 'credits'

include MiniGL

module Const
  SCR_W = 800
  SCR_H = 600
  TILE_SIZE = 32
  STOP_TIME_DURATION = 1800
  LAST_STAGE = 25
  MAX_ROWS = 15
  MAX_COLS = 25
end

class ConnecMan
  SYMBOLS_PER_LEVEL = [
    [0, 5], [3, 13], [19], [12], [8, 22], [], [25], [4, 9], [10, 11], [16, 17], [30], [], [2, 6], [1], [14, 15], [27], [7, 21], [], [18], [23, 26], [20, 28], [31], [24, 29], [], []
  ]
  
  class << self
    attr_reader :saves_path, :default_font, :image_font, :text_helper, :language, :mouse_control, :music_volume, :player
    attr_accessor :shortcut_keys, :full_screen, :sound_volume, :language_changed, :controls_changed
    
    def initialize(dir)
      Res.initialize

      @options_path = "#{dir}/config"
      @saves_path = "#{dir}/saves"

      @langs = []
      @texts = {}
      files = Dir["#{Res.prefix}text/*.txt"].sort
      files.each do |f|
        lang = f.split('/')[-1].chomp('.txt').to_sym
        @langs << lang
        @texts[lang] = {}
        File.open(f).each do |l|
          parts = l.split "\t"
          @texts[lang][parts[0].to_sym] = parts[-1].chomp
        end
      end

      if File.exist?(@options_path)
        content = File.read(@options_path).split(',')
        @language = @langs[content[0].to_i]
        @shortcut_keys = content[1] == '+'
        @mouse_control = content[2] == '+'
        @full_screen = content[3] == '+'
        @music_volume = content[4].to_i
        @sound_volume = content[5].to_i
      else
        FileUtils.mkdir_p(dir)
        create_options
      end

      @default_font = Res.font(:corbel, 24)
      @image_font = ImageFont.new(:font_font1, '0123456789AÁÃBCÇD:EÉ!FGH-IÍ?JKLMNÑOÓÔÕPQR¡¿STUVWXYZÚ()', 31, 41, 30)
      @text_helper = TextHelper.new(@default_font, 5, 0.75, 0.75)
      @transition_effects = [
        GameObject.new(0, -300, 800, 300, :fx_transition_1),
        GameObject.new(800, 0, 400, 600, :fx_transition_2),
        GameObject.new(0, 600, 800, 300, :fx_transition_3),
        GameObject.new(-400, 0, 400, 600, :fx_transition_4),
      ]

      @language_changed = Event.new
      @controls_changed = Event.new
    end

    def create_options
      @language = @langs[0]
      @shortcut_keys = true
      @mouse_control = true
      @full_screen = true
      @music_volume = 5
      @sound_volume = 10
      save_options
    end

    def save_options
      File.open(@options_path, 'w') do |f|
        lang = language_index
        shortcut_keys = @shortcut_keys ? '+' : '-'
        mouse_control = @mouse_control ? '+' : '-'
        full_screen = @full_screen ? '+' : '-'
        f.write("#{lang},#{shortcut_keys},#{mouse_control},#{full_screen},#{@music_volume},#{@sound_volume}")
      end
    end

    def show_presentation
      @controller = Opening.new
    end
    
    def show_main_menu(play_song = true)
      transition(play_song) do
        ConnecMan.play_song(Res.song(:Opening, true, '.mp3')) if play_song
        @controller = Menu.new
      end
    end
    
    def transition(stop_music = true, &callback)
      ConnecMan.play_sound('0')
      @transitioning = 0
      @stop_music = stop_music
      @callback = callback
    end

    def text(key)
      @texts[@language].fetch(key.to_sym, '???').gsub("\\n", "\n")
    end

    def play_song(song)
      cur_song = Gosu::Song.current_song
      cur_song.stop if cur_song
      song.volume = @music_volume * 0.1
      song.play(true)
    end

    def play_sound(id)
      Res.sound(id).play(@sound_volume * 0.1)
    end

    def language_index
      @langs.index(@language)
    end

    def change_language(delta)
      index = language_index
      index += delta
      if index < 0
        index = @langs.size - 1
      elsif index >= @langs.size
        index = 0
      end
      @language = @langs[index]
      @language_changed.invoke
    end

    def language=(value)
      @language = value
      @language_changed.invoke
    end
    
    def mouse_control=(value)
      @mouse_control = value
      @controls_changed.invoke
    end

    def music_volume=(value)
      @music_volume = value
      cur_song = Gosu::Song.current_song
      cur_song.volume = value * 0.1 if cur_song
    end

    def new_game
      @player = Player.new
      start_game
    end

    def load_game(name)
      data = File.read("#{@saves_path}/#{name}").split('#', -1)
      completed = data[0] == '!'
      level = data[1].to_i
      scores = data[2].split(',').map(&:to_i)
      @player = Player.new(name, completed, level, scores)
      start_game
    end

    def start_game
      transition do
        @controller = World.new(@player.last_world)
      end
    end

    def load_stage(world, index)
      transition do
        @prev_controller = @controller
        stage_num = (world - 1) * 6 + index + 1
        @controller = Stage.new(stage_num)
      end
    end

    def show_status
      transition(false) do
        @prev_controller = @controller
        @controller = StatusScreen.new
      end
    end
    
    def back
      transition(false) do
        @controller = @prev_controller
        @prev_controller = nil
      end
    end
    
    def back_to_world_map
      transition do
        @controller = @prev_controller
        @prev_controller = nil
        @controller.resume
      end
    end

    def save_game(name)
      FileUtils.mkdir_p(@saves_path) unless File.exist?(@saves_path)
      File.open("#{@saves_path}/#{name}", 'w') do |f|
        f.write("#{@player.completed ? '!' : ''}##{@player.last_stage}##{@player.scores.join(',')}")
      end
    end
    
    def next_level
      @player.last_stage += 1
      transition do
        @prev_controller.advance_level
        @controller = Stage.new(@controller.num + 1)
      end
    end
    
    def next_world
      @player.last_stage += 1
      @player.last_world += 1
      transition do
        @controller = World.new(@player.last_world)
      end
    end
    
    def show_game_end
      @player.completed = true
      transition do
        @controller = Credits.new
      end
    end

    def update
      if KB.key_pressed?(Gosu::KB_RETURN) && (KB.key_down?(Gosu::KB_LEFT_ALT) || KB.key_down?(Gosu::KB_RIGHT_ALT))
        @full_screen = !@full_screen
      end
      
      if @transitioning == 0
        @transition_effects.each_with_index do |t, i|
          aim = case i
                when 0, 3 then Vector.new(0, 0)
                when 1 then Vector.new(400, 0)
                when 2 then Vector.new(0, 300)
                end
          t.move_free(aim, i % 2 == 0 ? 6 : 8)
        end
        if @transition_effects[0].speed.y == 0
          Gosu::Song.current_song.stop if @stop_music && Gosu::Song.current_song
          @transitioning = 1
          @timer = 0
        end
      elsif @transitioning == 1
        @timer += 1
        if @timer == 30
          @callback.call
          @transitioning = 2
        end
      elsif @transitioning == 2
        @transition_effects.each_with_index do |t, i|
          aim = case i
                when 0 then Vector.new(0, -300)
                when 1 then Vector.new(800, 0)
                when 2 then Vector.new(0, 600)
                when 3 then Vector.new(-400, 0)
                end
          t.move_free(aim, i % 2 == 0 ? 6 : 8)
        end
        if @transition_effects[0].speed.y == 0
          @transitioning = nil
        end
      else
        @controller.update
      end
    end

    def draw
      @controller.draw
      @transition_effects.each(&:draw) if @transitioning
    end
  end
end

class CButton < Button
  def initialize(x, y = nil, font = nil, text_id = nil, img = nil,
                 text_color = 0, disabled_text_color = 0, over_text_color = 0, down_text_color = 0,
                 center_x = true, center_y = true, margin_x = 0, margin_y = 0, width = nil, height = nil,
                 params = nil, retro = nil, scale_x = 1, scale_y = 1, anchor = nil, &action)
    @text_id = text_id
    super(x, y, font, ConnecMan.text(text_id), img, text_color, disabled_text_color, over_text_color, down_text_color, center_x, center_y, margin_x, margin_y, width, height, params, retro, scale_x, scale_y, anchor, &action)
    ConnecMan.language_changed += Proc.new do
      self.text = ConnecMan.text(@text_id)
    end
  end
end