#!/usr/local/bin/ruby

# a terminal based minesweeper game
# usage for default size map 8x8 with 6 mines:
# ruby minesweeper.rb
# usage for custom size map:
# ruby minesweeper.rb <width> <height> <num_mines>
# to check cell enter letter and number, eg a1, b3
# to plant a flag put a hashtag in front eg #a1 #b2




class MinesweeperMap

  IS_FLAGGED = 0
  HAS_BOMB = 1
  IS_COVERED = 2

  attr_reader :width, :height, :num_bombs

  def initialize(width, height, num_bombs)
    @width = width
    @height = height
    @num_bombs = num_bombs
    @mine_map = []
    (0..width-1).each {
      column = []
      (0..height-1).each {
        column.push([false, false, true])
      }
      @mine_map.push(column)
    }
    place_bombs
  end

  def place_flag(x, y)
    @mine_map[x][y][IS_FLAGGED] = ! @mine_map[x][y][IS_FLAGGED]
  end

  def uncover_mine(x, y)
    @mine_map[x][y][IS_COVERED] = false
  end

  def has_bomb(x, y)
    @mine_map[x][y][HAS_BOMB]
  end

  def is_covered(x, y)
    @mine_map[x][y][IS_COVERED]
  end

  def has_flag(x, y)
    @mine_map[x][y][IS_FLAGGED]
  end

  def has_won
    count_covered == @num_bombs
  end

  def count_covered
    num_covered = 0
    (0..@height-1).each do |y|
      (0..@width-1).each do |x|
        if is_covered(x, y)
          num_covered += 1
        end
      end
    end
    num_covered
  end

  def num_bombs(x, y)
    count = 0
    ([0, x-1].max..[x+1, @width-1].min).each do |x_offset|
      ([0, y-1].max..[y+1, @height-1].min).each do |y_offset|
        if has_bomb(x_offset, y_offset)
          count +=1
        end
      end
    end
    count
  end

  private

  def place_bombs
    bombs_used = 0
    while bombs_used < @num_bombs
      x = rand(0..@width-1)
      y = rand(0..@height-1)
      if not has_bomb(x, y)
        @mine_map[x][y][HAS_BOMB] = true
        bombs_used += 1
      end
    end
  end

end

# handles input, and to_string to minesweeper map
class MinesweeperHandler

  def initialize(mine_map)
    @mine_map = mine_map
  end

  def handle_input(user_input)
    begin
      if user_input[0] == '#'
        handle_place_flag(user_input)
      else
        handle_uncover(user_input)
      end
    rescue
      :failure
    end
  end

  def to_string(show_bombs=false)
    map_string = build_header
    (0..@mine_map.height-1).each do |y|
      map_string += ('A'..'Z').to_a[y] + ' '
      (0..@mine_map.width-1).each do |x|
        map_string += build_marker(x, y, show_bombs) + ' '
      end
      map_string += "\n"
    end
    map_string
  end

  def to_coord(coord_str)
    y = coord_str[0].downcase.ord - 97 #ASCII value of 'a'
    x = coord_str[1..-1].to_i - 1
    return x, y
  end

  private

  def handle_place_flag(user_input)
    x, y = to_coord(user_input[1..-1])
    if @mine_map.is_covered(x, y)
      @mine_map.place_flag(x, y)
    end
    :success
  end

  def handle_uncover(user_input)
    x, y = to_coord(user_input)
    if not @mine_map.is_covered(x, y)
      return :already_uncovered
    elsif @mine_map.has_bomb(x, y)
      return :lose
    else
      @mine_map.uncover_mine(x, y)
      if @mine_map.has_won
        return :win
      end
    end
    :success
  end

  # returns the numbers at top of map
  def build_header
    map_string = ''
    if @mine_map.width > 9
      map_string = ('  ' * 10 + '1 ' * 10 + '2 ' * 10)[0..(@mine_map.width*2)] + "\n"
    end
    map_string + '  ' + (((0..9).to_a.join(' ') + ' ') * 3)[2..(@mine_map.width*2)] + "\n"
  end

  def build_marker(x, y, show_bombs)
    if show_bombs and @mine_map.has_bomb(x, y) # show bombs
      '*'
    elsif not @mine_map.is_covered(x, y) # show number of bombs
      @mine_map.num_bombs(x, y).to_s
    elsif @mine_map.has_flag(x, y) # show flag
      '#'
    else # show covered square
      '.'
    end
  end
end

DEFAULT_WIDTH = 8
DEFAULT_HEIGHT = 8
DEFAULT_NUM_MINES = 6

if ARGV.length == 3
  mine_map = MinesweeperMap.new(ARGV[0].to_i, ARGV[1].to_i, ARGV[2].to_i)
else
  mine_map = MinesweeperMap.new(DEFAULT_WIDTH, DEFAULT_HEIGHT, DEFAULT_NUM_MINES)
end

mine_map_handler = MinesweeperHandler.new(mine_map)
print mine_map_handler.to_string
while true
  print 'What cell do you want to check? '
  user_input = STDIN.gets.chomp
  result = mine_map_handler.handle_input(user_input)
  case result
    when :success # successful placement
      print mine_map_handler.to_string
    when :failure # bad placement
      puts "I don't understand."
    when :already_uncovered
      puts 'This cell is already uncovered.'
    when :win
      puts 'you won!'
      puts mine_map_handler.to_string show_bombs=true
      exit
    when :lose
      puts 'BOOM BOOM BOOM BOOM BOOM'
      puts mine_map_handler.to_string show_bombs=true
      exit
  end
end

