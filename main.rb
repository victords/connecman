require 'minigl'
require 'rbconfig'
require_relative 'menu'

include MiniGL

class ConnecManWindow < GameWindow
  def initialize
    os = RbConfig::CONFIG['host_os']
    dir =
      if /linux/ =~ os
        "#{Dir.home}/.vds-games/connecman"
      else
        "#{Dir.home}/AppData/Local/VDS Games/ConnecMan"
      end
    ConnecMan.initialize(dir)
    super(Const::SCR_W, Const::SCR_H, ConnecMan.full_screen)

    @state = :main_menu
    @menu = Menu.new
    @menu.show_main_menu
  end

  def update
    KB.update
    Mouse.update

    case @state
    when :opening

    end
  end

  def draw
    case @state
    when :opening

    when :main_menu
      @menu.draw
    end
  end
end

ConnecManWindow.new.show
