require 'minigl'
require 'rbconfig'
require_relative 'global'

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

    ConnecMan.show_presentation
  end

  def needs_cursor?
    false
  end

  def update
    KB.update
    Mouse.update
    ConnecMan.update
  end

  def draw
    ConnecMan.draw
  end
end

ConnecManWindow.new.show
ConnecMan.save_options
