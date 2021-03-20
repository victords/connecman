require 'fileutils'

module Const
  SCR_W = 800
  SCR_H = 600
end

class ConnecMan
  LANGUAGES = {
    0 => :english,
    1 => :portuguese,
    2 => :spanish
  }

  class << self
    attr_reader :language, :shortcut_keys, :mouse_control, :full_screen, :music_volume, :sound_volume

    def initialize(dir)
      @options_path = "#{dir}/config"
      @saves_path = "#{dir}/saves"

      if File.exist?(@options_path)
        content = File.read(@options_path).split(',')
        @language = LANGUAGES[content[0].to_i]
        @shortcut_keys = content[1] == '+'
        @mouse_control = content[2] == '+'
        @full_screen = content[3] == '+'
        @music_volume = content[4].to_i
        @sound_volume = content[5].to_i
      else
        FileUtils.mkdir_p(dir)
        create_options
      end
    end

    def create_options
      @language = LANGUAGES[0]
      @shortcut_keys = true
      @mouse_control = true
      @full_screen = true
      @music_volume = 5
      @sound_volume = 10
      save_options
    end

    def save_options
      File.open(@options_path, 'w') do |f|
        lang = LANGUAGES.key(@language)
        shortcut_keys = @shortcut_keys ? '+' : '-'
        mouse_control = @mouse_control ? '+' : '-'
        full_screen = @full_screen ? '+' : '-'
        f.write("#{lang},#{shortcut_keys},#{mouse_control},#{full_screen},#{@music_volume},#{@sound_volume}")
      end
    end

    def play_song(song)
      cur_song = Gosu::Song.current_song
      if cur_song
        return if cur_song == song
        cur_song.stop
      end
      song.volume = @music_volume * 0.1
      song.play(true)
    end
  end
end