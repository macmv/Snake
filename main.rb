#! /usr/local/bin/ruby

# |\    |  |-----  \            /        |---\   |-----   /-----   /---\   |---\   |---\   | | |
# | \   |  |        \          /         |    |  |       |        |     |  |    |  |    |  | | |
# |  \  |  |--       \        /          |---/   |--     |        |     |  |---/   |    |  | | |
# |   \ |  |          \  /\  /           |   \   |       |        |     |  |   \   |    |  
# |    \|  |-----      \/  \/            |    \  |-----   \-----   \---/   |    \  |---/   . . .

require "gosu"
require "trollop"
require "../Gosu_Library.rb"

$opts = Trollop::options do
	opt :fullscreen, "Go fullscreen"
end

def time_diff_milli(start, finish)
   (finish - start) * 1000.0
end

module Snake

WIDTH = 800
HEIGHT = 600
BLOCKSIZE = 20
	
private

class Board

	def draw
		draw_rect(0                , 0                 , BLOCKSIZE, HEIGHT   , 0xff_cccccc) # 1 |--4---|
		draw_rect(0                , HEIGHT - BLOCKSIZE, WIDTH    , BLOCKSIZE, 0xff_cccccc) # 2 |      3
		draw_rect(WIDTH - BLOCKSIZE, 0                 , BLOCKSIZE, HEIGHT   , 0xff_cccccc) # 3 1      |
		draw_rect(0                , 0                 , WIDTH    , BLOCKSIZE, 0xff_cccccc) # 4 |---2--|
	end

end

class Apple

	attr_reader :x, :y

	def initialize(arg1, arg2, arg3)
		@x = rand(WIDTH  / BLOCKSIZE - 2) + 1
		@y = rand(HEIGHT / BLOCKSIZE - 2) + 1
		@image = Gosu::Image.new arg1, arg2, arg3
	end

	def draw
		@image.draw(@x * BLOCKSIZE, @y * BLOCKSIZE, 0)
	end

	def move
		@x = rand(WIDTH  / BLOCKSIZE - 2) + 1
		@y = rand(HEIGHT / BLOCKSIZE - 2) + 1
	end

end

class SnakeSegment

	attr_reader :x, :y

	def initialize(x, y)
		@x = x
		@y = y
	end

	def draw
		draw_rect(@x * BLOCKSIZE, @y * BLOCKSIZE, BLOCKSIZE, BLOCKSIZE, 0xff_0000dd)
	end

	def ==(other)
		return false if !(other.class == SnakeSegment || other.class == Apple)
		self.x == other.x && self.y == other.y
	end

	def off_screen?
		@x <= 0 || @x >= WIDTH / BLOCKSIZE || @y <= 0 || @y >= WIDTH / BLOCKSIZE
	end

end

class Snake

	def initialize
		@segments = [SnakeSegment.new(5, 5), SnakeSegment.new(6, 5), SnakeSegment.new(7, 5), SnakeSegment.new(8, 5), SnakeSegment.new(9, 5)]
		@direction = :right
		@next_direction = :right
	end

	def draw
		@segments.each do |segment|
			segment.draw
		end
	end

	def update(apple)
		@direction = @next_direction
		old_last_x = @segments.last.x
		old_last_y = @segments.last.y
		if @direction == :left
			@segments.push SnakeSegment.new(old_last_x - 1, old_last_y)
		elsif @direction == :right
			@segments.push SnakeSegment.new(old_last_x + 1, old_last_y)
		elsif @direction == :up
			@segments.push SnakeSegment.new(old_last_x, old_last_y - 1)	
		elsif @direction == :down
			@segments.push SnakeSegment.new(old_last_x, old_last_y + 1)
		else
			raise "@direction is ilegal value"	
		end
		return_val = nil
		if is_tuching?(:apple, apple)
			return_val = :move_apple
		else
			@segments.shift
		end
		if is_tuching?(:wall, apple)
			return_val = :hit_wall
		end
		if is_tuching?(:self, apple)
			return_val = :hit_self
		end
		return return_val
	end

	def is_tuching?(thing, apple)
		@segments.each do |segment|
			if segment.off_screen? && thing == :wall
				return true
			end
			if segment == apple && thing == :apple
				return true
			end
			if thing == :self
				@segments.each do |other_segment|
					if segment == other_segment && segment.inspect != other_segment.inspect
						return true
					end
				end
			end
		end
		false
	end

	def set_direction(direction)
		if @direction == :right && direction == :left
			return
		elsif @direction == :left && direction == :right
			return
		elsif @direction == :up && direction == :down
			return
		elsif @direction == :down && direction == :up
			return
		end
		@next_direction = direction
	end

end

public

class Screen < Gosu::Window

	def initialize
		super WIDTH, HEIGHT, $opts[:fullscreen]
		self.caption = "Snake"
		@board = Board.new
		@snake = Snake.new
		@apple = Apple.new self, Circle.new(BLOCKSIZE / 2, 0, 255, 0), false
		@score = 0
		@old_time = Time.new
		@font = Gosu::Font.new 20
	end

	def draw
		@board.draw
		@snake.draw
		@apple.draw
		@font.draw("Score: #{@score}", BLOCKSIZE, BLOCKSIZE, 0, BLOCKSIZE.to_f / 20.0, BLOCKSIZE.to_f / 20.0, 0xff_ffcc00)
	end

	def update
		if time_diff_milli(@old_time, Time.new) > 300
			return_val = @snake.update @apple
			if return_val == :move_apple
				@apple.move
				@score += 1
			elsif return_val == :hit_wall || return_val == :hit_self
				if @score > File.read("record.txt").to_i
					puts '|\    |  |-----  \            /        |---\   |-----   /-----   /---\   |---\   |---\   | | |'
						 '| \   |  |        \          /         |    |  |       |        |     |  |    |  |    |  | | |'
						 '|  \  |  |--       \        /          |---/   |--     |        |     |  |---/   |    |  | | |'
						 '|   \ |  |          \  /\  /           |   \   |       |        |     |  |   \   |    |'
						 '|    \|  |-----      \/  \/            |    \  |-----   \-----   \---/   |    \  |---/   . . .'
					File.open("record.txt", "w") { |f| f.write @score }
				end
				exit
			end
			@old_time = Time.new
		end
		if Gosu::button_down?(Gosu::KbW) || Gosu::button_down?(Gosu::KbUp)
			@snake.set_direction :up
		end
		if Gosu::button_down?(Gosu::KbA) || Gosu::button_down?(Gosu::KbLeft)
			@snake.set_direction :left
		end
		if Gosu::button_down?(Gosu::KbS) || Gosu::button_down?(Gosu::KbDown)
			@snake.set_direction :down
		end
		if Gosu::button_down?(Gosu::KbD) || Gosu::button_down?(Gosu::KbRight)
			@snake.set_direction :right
		end
	end

end

end

Snake::Screen.new.show