require 'rubygems'
require 'rmagick'
require 'ruby-debug'

@@sweepline = 0

class Coord
	attr_accessor :x, :y

	def distance_to another
    	Math::hypot another.x - self.x, another.y - self.y
  	end

  	def initialize x, y
  		@x = x
  		@y = y
  	end
end

class Vertex
	attr_accessor :coord, :halfedge

	def initialize coord
		@coord = coord
	end

	def x
		@coord.x
	end

	def y
		@coord.y
	end
end

class Halfedge
	attr_accessor :vertex, :next, :prev, :site, :twin
	
	def initialize vertex
		@vertex = vertex
	end

	def next=(nextHE)
		@next = nextHE
		nextHE.prev = self
	end
end

class Site
	attr_accessor :center, :halfedge, :v
	@@canvas = Magick::Image.new(500, 500, Magick::HatchFill.new('white','lightcyan2'))

	def initialize center
		@center = center;
	end

	def initialize x, y
		@center = Coord.new x, y
	end

	def x
		@center.x
	end

	def y
		@center.y
	end

	def draw
		g = Magick::Draw.new
		g.stroke '#FF0000'
		g.stroke_width 3
		g.fill 'transparent'

		if (@halfedge)
			he = @halfedge
			path = "M#{he.vertex.x}, #{he.vertex.y} "
			he = he.next
			while he != @halfedge
				path += "L#{he.vertex.x}, #{he.vertex.y} "
				he = he.next
			end
			path += "z"
			# @halfedge.vertex.x, @halfedge.vertex.y, @halfedge.next.vertex.x, @halfedge.next.vertex.y, @halfedge.next.next.vertex.x, @halfedge.next.next.vertex.y, @halfedge.next.next.next.vertex.x, @halfedge.next.next.next.vertex.y
			g.path path
		end

		g.stroke '#000000'
		g.stroke_width 1

		g.circle @center.x, @center.y, @center.x - 3, @center.y

		g.stroke '#0000FF'
		if (@@sweepline > @center.y)
			Site.draw_parabola @center, @@sweepline
			a = 1.0 / ( 2 * @center.y - 2 * @@sweepline )
			b = -1.0 * @center.x / ( @center.y - @@sweepline )
			c = 1.0 * ( @center.x ** 2 + @center.y ** 2 - @@sweepline ** 2 ) / ( 2 * @center.y - 2 * @@sweepline )
			@v = [a, b, c]
		end

		g.draw @@canvas
	end

	def Site.save image
		@@canvas.write image
	end

	def to_s
		"[#{center.x}, #{center.y}]"
	end

	def Site.canvas
		@@canvas
	end

	def Site.clear_canvas
		@@canvas = Magick::Image.new(500, 500, Magick::HatchFill.new('white','lightcyan2'))
	end

	def Site.draw_parabola point, sweepline
		d = Magick::Draw.new
		d.stroke '#FF0000'
		d.stroke_width 2
		d.fill 'transparent'
		alpha = Math.sqrt sweepline ** 2 - point.y ** 2
		a = Coord.new point.x - alpha, 0
		b = Coord.new point.x, point.y + sweepline
		c = Coord.new point.x + alpha, 0
		d.path "M#{a.x},#{a.y} Q#{b.x},#{b.y} #{c.x},#{c.y}"
		d.draw @@canvas
	end

	def Site.find_intersection s1, s2
		# debugger
		# a = s1.v[0] - s2.v[0]
		# b = s1.v[1] - s2.v[1]
		# c = s1.v[2] - s2.v[2]
		# x1 = ( - b + Math.sqrt( b ** 2 - 4 * a * c ) ) / ( 2 * a )
		# y1 = s1.v[0] * (x1 ** 2) + s1.v[1] * x1 + s1.v[2]
		# x2 = ( - b - Math.sqrt( b ** 2 - 4 * a * c ) ) / ( 2 * a )
		# y2 = s2.v[0] * (x2 ** 2) + s2.v[1] * x2 + s2.v[2]
		# debugger
		x1 = s1.x
		x2 = s2.x
		y1 = s1.y
		y2 = s2.y
		l = Magick::Draw.new
		l.fill '#000000'
		dx = 1.0 * s2.x - s1.x
		dy = 1.0 * s2.y - s1.y
		c = x1 * dx + y1 * dy + ( dx ** 2 + dy ** 2 ) / 2
		if (dx.abs > dy.abs)
			a = 1.0
			b = dy / dx
			c /= dx
		else
			a = dx / dy
			b = 1.0
			c /= dy
		end
		debugger
		x1 = 0
		x2 = 500
		y1 = -1.0 * ( a * x1 + c ) / b
		y2 = -1.0 * ( a * x2 + c ) / b
		x0 = -1.0 * ( b * @@sweepline + c ) / a
		l.path "M#{x1},#{y1} L#{x2},#{y2}"
		l.path "M#{x0},#{0} L#{x0},#{500}"
		# l.circle x1, y1, x1 - 3, y1
		# l.circle x2, y2, x2 - 3, y2
		# l.fill 'transparent'
		# l.stroke "rgb(#{Random.new.rand(0..255)},#{Random.new.rand(0..255)},#{Random.new.rand(0..255)})"
		# l.stroke_width 1
		# l.stroke_dasharray 10, 10
		# l.circle x1, y1, s1.x, s1.y
		# l.circle x2, y2, s1.x, s1.y
		l.draw @@canvas
		# [Coord.new(x1,y1), Coord.new(x2,y2)]
	end
end

class EventQueue

	attr_accessor :events

	def add_event event
		if (!@events)
			@events = []
		end
		@events << event
		@events.sort! do |a, b|
			a.y <=> b.y
		end
	end

	def rm_event event
		@events.delete event
	end

	def past_events
		@events.reject do |e|
			e.y >= @@sweepline
		end
	end
end

class Event
end

class SiteEvent < Event
	attr_accessor :site
	# attr_reader :coord

	def initialize site
		@site = site
	end

	def x
		@site.center.x
	end

	def y
		@site.center.y
	end
end


# class CircleEvent < Event
# end

class Node
	attr_accessor :left, :right, :parent, :value

	def root?
		!@parent
	end

	def leaf?
		!(@left || @right)
	end

	def left=(value)
		@left = value
		value.parent = self
	end

	def right=(value)
		@right = value
		value.parent = self
	end

end

class Arc < Node
	attr_accessor :site

	def initialize site
		@value = site
	end
end

class Breakpoint < Node

end

class Tree
	attr_accessor :root

	def add_node value
		# debugger
		unless @root
			@root = Arc.new value
		else
			i = @root
			until i.leaf?
				i = (value.x < i.value.x) ? i.left : i.right
			end
			if (value.x < i.value.x)
				n = Breakpoint.new
				if (i.parent)
					n.parent = i.parent
				else
					self.root = n
				end
				n.left = Arc.new value
				n.right = i
			else
				n = Breakpoint.new
				if (i.parent)
					n.parent = i.parent
				else
					self.root = n
				end
				n.left = i
				n.right = Arc.new value
			end

		end
	end
end

def main i=1
	# #------
	# he1 = Halfedge.new Vertex.new Coord.new 100, 100
	# he2 = Halfedge.new Vertex.new Coord.new 100, 400
	# he1.next = he2
	# he3 = Halfedge.new Vertex.new Coord.new 400, 400
	# he2.next = he3
	# he4 = Halfedge.new Vertex.new Coord.new 400, 100
	# he3.next = he4
	# he4.next = he1
	# s = Site.new 200, 200
	# s.halfedge = he1
	# #------
	# s.draw

	# sites = []
	# r = Random.new
	# 5.times do
	# 	sites << Site.new(r.rand(100..400), r.rand(100..400))
	# end

	# sites.each do |s| 
	# 	# puts s
	# 	s.draw
	# end

	# Site.save "jpeg:image"

	# eq = EventQueue.new
	# sites.each do |s|
	# 	eq.add_event Event.new s.center
	# end

	# puts eq.events

	# `open image`

	sites = [Site.new(300, 50), Site.new(200, 130), Site.new(400, 300)]
	eq = EventQueue.new
	sites.each do |s|
		eq.add_event SiteEvent.new s
	end

	@@sweepline = 300

	# t = Tree.new
	# t.add_node eq.events[0].site
	# puts t.root
	# t.add_node eq.events[1].site
	# puts t.root
	# @@sweepline = 500
	l = Magick::Draw.new
	l.stroke '#000000'
	l.stroke_width 1
	l.fill 'transparent'
	l.path "M0,#{@@sweepline} L500,#{@@sweepline}"

	sites.each do |s|
		s.draw
	end

	eq.past_events.combination(2).to_a.each do |a|
		# debugger
		Site.find_intersection a[0].site, a[1].site
	end

	l.draw Site.canvas

	Site.save "jpeg:image#{i}"
	Site.clear_canvas
end


# (130..300).each {|i| main i}
main