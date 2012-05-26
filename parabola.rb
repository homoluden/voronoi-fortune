require 'rubygems'
require 'rmagick'
# require 'ruby-debug'

class Coord
	attr_accessor :x, :y

	def distance_to another
    	Math::hypot another.x - self.x, another.y - self.y
  	end

  	def initialize x, y
  		@x = x.to_f
  		@y = y.to_f
  	end
end

class MVector
	attr_accessor :start, :end

	def initialize start_p, end_p
		@start = start_p
		@end = end_p
	end

	def twin
		MVector.new @end, @start
	end

	def x
		@end.x - @start.x
	end

	def y
		@end.y - @start.y
	end

end

def draw_point a, c
	c.circle a.x, a.y, a.x - 3, a.y
end

def draw_parabola a, b, c, dr # a, b – directrix points, c – focus, dr – Magick::Draw
	ab = MVector.new a, b
	ac = MVector.new a, c
	bc = MVector.new b, c

	n = ( ac.x ** 2 + ac.y ** 2 ) / ( 2.0 * ( ab.x * ac.y - ab.y * ac.x ) )

	d = Coord.new a.x - ab.y * n, a.y + ab.x * n

	n = ( bc.x ** 2 + bc.y ** 2 ) / ( 2.0 * ( ab.x * bc.y - ab.y * bc.x ) )

	e = Coord.new b.x - ab.y * n, b.y + ab.x * n

	f = Coord.new ( a.x + c.x ) * 0.5, ( a.y + c.y ) * 0.5

	g = Coord.new ( b.x + c.x ) * 0.5, ( b.y + c.y ) * 0.5

	n = ( ( g.x - f.x ) * ac.x + ( g.y - f.y ) * ac.y ) / ( bc.y * ac.x - bc.x * ac.y )

	h = Coord.new g.x - bc.y * n, g.y + bc.x * n

	dr.fill "transparent"

	dr.path "M#{d.x},#{d.y} Q#{h.x},#{h.y} #{e.x},#{e.y}"
end

canvas = Magick::Image.new 500, 500, Magick::HatchFill.new('white','lightcyan2')
d = Magick::Draw.new

d.stroke "black"
d.stroke_width 1

a = Coord.new 0, 350
b = Coord.new 100, 350
f = Coord.new 150, 300

draw_parabola a, b, f, d

a.x = 100
b.x = 500

d.stroke "red"
d.stroke_width 3

draw_parabola a, b, f, d

d.draw canvas
canvas.write "jpeg:img"
`open img`