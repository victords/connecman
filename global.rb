require 'fileutils'
require_relative 'event'
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
    attr_reader :saves_path, :default_font, :image_font, :text_helper, :language, :music_volume, :player
    attr_accessor :shortcut_keys, :mouse_control, :full_screen, :sound_volume, :language_changed
    
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
      @image_font = ImageFont.new(:font_font1, '0123456789AÁÃBCÇD:EÉ!FGH-IÍ?JKLMNÑOÓÔÕPQR¡¿STUVWXYZÚ', 31, 41, 30)
      @text_helper = TextHelper.new(@default_font, 5, 0.75, 0.75)
      @cursor = Res.img(:cursor_Default, true)

      @language_changed = Event.new
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

    def show_main_menu
      @controller = Menu.new
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
      @controller = World.new(@player.last_world)
    end

    def load_stage(world, index)
      @prev_controller = @controller
      stage_num = (world - 1) * 6 + index + 1
      @controller = Stage.new(stage_num)
    end

    def show_status
      @prev_controller = @controller
      @controller = StatusScreen.new
    end
    
    def back
      @controller = @prev_controller
      @prev_controller = nil
    end
    
    def back_to_world_map
      back
      @controller.resume
    end

    def save_game(name)
      File.open("#{@saves_path}/#{name}", 'w') do |f|
        f.write("#{@player.completed ? '!' : ''}##{@player.last_stage}##{@player.scores.join(',')}")
      end
    end
    
    def next_level
      @player.last_stage += 1
      @prev_controller.advance_level
      @controller = Stage.new(@controller.num + 1)
    end
    
    def next_world
      @player.last_stage += 1
      @player.last_world += 1
      @controller = World.new(@player.last_world)
    end
    
    def show_game_end
      @player.completed = true
      @controller = Credits.new
    end

    def update
      if KB.key_pressed?(Gosu::KB_RETURN) && (KB.key_down?(Gosu::KB_LEFT_ALT) || KB.key_down?(Gosu::KB_RIGHT_ALT))
        @full_screen = !@full_screen
      end
      
      @controller.update
    end

    def draw
      @controller.draw
      @cursor.draw(Mouse.x - @cursor.width / 2, Mouse.y, 10) unless @controller.is_a?(Stage)
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