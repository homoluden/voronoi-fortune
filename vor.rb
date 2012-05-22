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
	attr_accessor :center, :halfedge
	@@canvas = Magick::Image.new(500, 500, Magick::HatchFill.new('white','lightcyan2'))

	def initialize center
		@center = center;
	end

	def initialize x, y
		@center = Coord.new x, y
	end

	def draw
		g = Magick::Draw.new
		g.stroke '#FF0000'
		g.stroke_width 3

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
		p = self.parabola @@sweepline
		g.bizier p[:p1].x, p[:p1].y, p[:cp].x, p[:cp].y, p[:cp].x, p[:cp].y, p[:p2].x, p[:p2].y if (p)

		g.draw @@canvas
	end

	def Site.save image
		@@canvas.write image
	end

	def to_s
		"[#{center.x}, #{center.y}]"
	end

	def parabola sweepline
		if (sweepline == @center.y)
			return nil
		end
		parabolaPoint0 = Coord.new @center.x, sweepline / 2 + @center.y / 2
    
	    a1 = (@center.x - 5) - @center.x;
	    b1 = sweepline - @center.y;
	    c1 = ( @center.x * @center.x - (@center.x - 5) * (@center.x - 5) + @center.y * @center.y - sweepline * sweepline ) / 2;
	    
	    parabolaPoint1 = Coord.new @center.x, (- c1 - a1 * (@center.x - 5)) / b1
	    parabolaPoint2 = Coord.new 2 * parabolaPoint0.x - parabolaPoint1.x, parabolaPoint1.y

	    debugger
	    
	    a2 = ( parabolaPoint2.y - ( parabolaPoint2.x * ( parabolaPoint1.y - parabolaPoint0.y) + parabolaPoint1.x * parabolaPoint0.y - parabolaPoint0.x * parabolaPoint1.y ) / ( parabolaPoint1.x - parabolaPoint0.x ) ) / ( parabolaPoint2.x * ( parabolaPoint2.x - parabolaPoint0.x - parabolaPoint1.x ) + parabolaPoint0.x * parabolaPoint1.x )
	    b2 = ( parabolaPoint1.y - parabolaPoint0.y ) / (parabolaPoint1.x - parabolaPoint0.x ) - a2 * ( parabolaPoint0.x + parabolaPoint1.x )
	    c2 = ( parabolaPoint1.x * parabolaPoint0.y - parabolaPoint0.x * parabolaPoint1.y ) / ( parabolaPoint1.x - parabolaPoint0.x ) + a2 * parabolaPoint0.x * parabolaPoint1.x
	    
	    parabolaPoint1 = Coord.new(( - b2 + sqrt( b2 * b2 - 4 * a2 * c2 ) ) / ( 2 * a2 ), 0)
	    parabolaPoint2 = Coord.new(( - b2 - sqrt( b2 * b2 - 4 * a2 * c2 ) ) / ( 2 * a2 ), 0)
	    controlPoint = Coord.new parabolaPoint0.x, ( a2 * parabolaPoint1.x * parabolaPoint1.x + b2 * parabolaPoint1.x + c2 ) + ( 2 * a2 * parabolaPoint1.x + b2 ) * ( parabolaPoint0.x - parabolaPoint1.x )
	    
	    # a, b, c-keys: a*x^2+b*x+c=y
	    {:a => a2, :b => b2, :c => c2, :p1 => parabolaPoint1, :p2 => parabolaPoint2, :cp => controlPoint}
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

end

class Event
	attr_accessor :coord

	def initialize coord
		@coord = coord
	end

	def x
		@coord.x
	end

	def y
		@coord.y
	end

	def to_s
		"[#{@coord.x}, #{@coord.y}]"
	end

end

# class SiteEvent < Event
# end

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
		unless @root
			@root = Arc.new value
		else
			i = @root
			until i.leaf?
				i = (value < i.value) ? i.left : i.right
			end
			if (value < i.value)
				n = Breakpoint.new
				n.parent = i.parent
				n.left = Arc.new value
				n.right = i
			else
				n = Breakpoint.new
				n.parent = i.parent
				n.left = i
				n.right = Arc.new value
			end

		end
	end
end

def main
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

	sites = [Site.new(50, 100), Site.new(200, 200)]
	eq = EventQueue.new
	sites.each do |s|
		eq.add_event Event.new s.center
	end

	@@sweepline = eq.events[1].y

	sites.each do |s| 
		# puts s
		s.draw
	end
end



main