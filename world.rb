class World
  def initialize(num, stage_num)
    @bg = Res.img("map_Map#{num}")
    @water = Res.img(:map_water, true, true)
    @bgm = Res.song("world#{num}", false, '.mp3')

    @stage_index = stage_num
    @water_timer = 0

    ConnecMan.play_song(@bgm)
  end

  def update
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
  end
end
