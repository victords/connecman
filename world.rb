include MiniGL

class World
  def initialize(num, stage_num)
    @num = num

    @bg = Res.img("map_Map#{num}")
    @water = Res.img(:map_water, true, true)

    spots = case @num
            when 1 then [[200, 370], [282, 490], [515, 407], [340, 380], [477, 319], [515, 232]]
            when 2 then [[418, 542], [321, 495], [279, 377], [439, 308], [730, 415], [295, 118]]
            when 3 then [[367, 97], [220, 207], [212, 348], [267, 478], [639, 386], [472, 334]]
            when 4 then [[206, 327], [220, 447], [454, 521], [616, 403], [604, 277], [405, 266]]
            else        [[347, 329]]
            end
    @spots = spots[0..stage_num].map { |s| Vector.new(s[0], s[1]) }
    @spot_buttons = []
    @spots.each_with_index do |s, i|
      @spot_buttons << Button.new(s.x - 16, s.y - 12, nil, nil, :map_Spot) {
        @cur_spot = i
      }
    end
    @cur_spot = stage_num
    @man = GameObject.new(@spots[@cur_spot].x, @spots[@cur_spot].y, 0, 0, :map_man, Vector.new(-16, -54), 5, 1)

    @water_timer = 0

    @bgm = Res.song("world#{num}", false, '.mp3')
    ConnecMan.play_song(@bgm)
  end

  def update
    @spot_buttons.each_with_index do |s, i|
      s.update if i != @cur_spot
    end

    @man.animate([0, 1, 2, 1, 0, 3, 4, 3], 8)
    if @man.x != @spots[@cur_spot].x || @man.y != @spots[@cur_spot].y
      @man.move_free(@spots[@cur_spot], 4)
    end

    @water_timer += 1
    @water_timer = 0 if @water_timer == 40
  end

  def draw
    offset = @water_timer < 20 ? 0 : 10
    (0..4).each do |i|
      (0..2).each do |j|
        @water.draw((i - 1) * 200 + offset, j * 201, 0)
      end
    end

    @bg.draw(0, 0, 0)
    @spot_buttons.each(&:draw)
    @spots.each_with_index do |s, i|
      ConnecMan.image_font.draw_text_rel((i + 1).to_s, s.x, s.y - 10, 0, 0.5, 0, 0.3, 0.3, 0xff000000)
    end
    @man.draw

    ConnecMan.image_font.draw_text(ConnecMan.text("world_#{@num}").upcase, 50, 10, 0, 0.8, 0.8, 0xffffffff)
    ConnecMan.image_font.draw_text(ConnecMan.text(:player) + ConnecMan.player.name.upcase, 10, 540, 0, 0.5, 0.5, 0xffffffff)
    ConnecMan.image_font.draw_text(ConnecMan.text(:score) + ConnecMan.player.scores.sum.to_s, 10, 570, 0, 0.5, 0.5, 0xffffffff)
  end
end
