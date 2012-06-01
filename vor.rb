require 'rubygems'
require 'rmagick'
require 'matrix'
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
	attr_accessor :vertex, :next, :prev, :site, :twin, :end
	
	def initialize vertex
		@vertex = vertex
	end

	def next=(nextHE)
		@next = nextHE
		nextHE.prev = self
	end
end

class Site
	attr_accessor :center, :halfedge, :a, :b, :c
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
			self.find_parabola
		end

		g.draw @@canvas
	end

	def Site.save image
		@@canvas.write image
	end

	def to_s
		"[#{center.x}, #{center.y}]"
	end

	def find_parabola
		@a = 1.0 / ( 2 * @center.y - 2 * @@sweepline )
		@b = -1.0 * @center.x / ( @center.y - @@sweepline )
		@c = 1.0 * ( @center.x ** 2 + @center.y ** 2 - @@sweepline ** 2 ) / ( 2 * @center.y - 2 * @@sweepline )
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
		s1.find_parabola
		s2.find_parabola
		if s1.y == @@sweepline
			x1 = s1.x
			y1 = s2.a * (x1 ** 2) + s2.b * x1 + s2.c
			ret = Coord.new(x1,y1)
			[ret, ret]
		elsif s2.y == @@sweepline
			x1 = s2.x
			y1 = s1.a * (x1 ** 2) + s1.b * x1 + s1.c
			ret = Coord.new(x1,y1)
			[ret, ret]
		else
			a = s1.a - s2.a
			b = s1.b - s2.b
			c = s1.c - s2.c
			x1 = ( - b + Math.sqrt( b ** 2 - 4 * a * c ) ) / ( 2 * a )
			y1 = s1.a * (x1 ** 2) + s1.b * x1 + s1.c
			x2 = ( - b - Math.sqrt( b ** 2 - 4 * a * c ) ) / ( 2 * a )
			y2 = s2.a * (x2 ** 2) + s2.b * x2 + s2.c
			if (x1 < x2)
				[Coord.new(x1,y1), Coord.new(x2,y2)]
			else
				[Coord.new(x2,y2), Coord.new(x1,y1)]
			end
		end
	end
end

class EventQueue

	attr_accessor :current

	def add_event event
		# debugger
		if @current == nil
			self.current = event
		else
			i = @current
			if event.y < i.y
				event.next = i
				i.prev = event
				self.current = event
			else
				while event.y > i.y && i.next != nil
					i = i.next
				end
				if event.y > i.y
					i.next = event
					event.prev = i
				else
					debugger if i.prev == nil
					# return if event.x.rationalize == i.x.rationalize && event.y.rationalize == i.y.rationalize
					event.prev = i.prev
					i.prev.next = event
					event.next = i
				end
				# debugger
			end
		end
	end

	def rm_event event
		event.next.prev = event.prev if (event.next)
		event.prev.next = event.next if (event.prev)
		self.current = event.next if (event == @current)
	end

	def pop
		r = self.current
		self.rm_event self.current
		r
	end
end

class Event
	attr_accessor :prev, :next # previous and next
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


class CircleEvent < Event
	attr_accessor :left, :mid, :right, :coord, :center

	def initialize left, mid, right, coord, center
		@left = left
		@mid = mid
		@right = right
		@coord = coord
		@center = center
	end

	def x
		@coord.x
	end

	def y
		@coord.y
	end
end

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

@@bpc = 0
@@anc = 0

class Arc < Node
	attr_accessor :right_point, :left_point
	attr_reader :name
	def initialize site, left_point = nil, right_point = nil, name = nil
		@value = site
		@right_point = right_point
		@left_point = left_point
		if (!name)
			@@anc += 1
			@name = "A#{@@anc}"
		else
			@name = name
		end
	end
end

class Breakpoint < Node
	attr_accessor :right_arc, :left_arc, :halfedge
	attr_reader :name

	def initialize left, right, type, name = nil
		@right_arc = right
		@left_arc = left
		@type = type
		if (!name)
			@@bpc += 1
			@name = "B#{@@bpc}"
		else
			@name = name
		end
		@halfedge = Halfedge.new self.value
	end

	def right?
		@type
	end

	def change_type type
		@type = type
	end

	def value
		b1, b2 = Site.find_intersection @right_arc, @left_arc
		if (self.right?)
			@halfedge.end = b2 if @halfedge
			b2
		else
			@halfedge.end = b1 if @halfedge
			b1
		end
	end
end

class Tree
	attr_accessor :root

	def finish_edges
		inorder @root
	end

	def rm_arc event
		arc = event.mid
		a = arc_array
		i = a.index arc
		# left_arc = arc.left_point.left_arc
		# right_arc = arc.right_point.right_arc
		left_point = arc.left_point
		right_point = arc.right_point
		left_point.halfedge.end = event.center
		right_point.halfedge.end = event.center
		left_arc = a[ i - 1 ]
		right_arc = a[ i + 1 ]
		if (left_arc.value.halfedge)
			i = left_arc.value.halfedge
			while i.next
				i = i.next
			end
			# debugger
			i.next = left_point.halfedge
		else
			# debugger
			left_arc.value.halfedge = left_point.halfedge
		end
		if (right_arc.value.halfedge)
			i = right_arc.value.halfedge
			while i.next
				i = i.next
			end
			# debugger
			i.next = right_point.halfedge
		else
			# debugger
			right_arc.value.halfedge = right_point.halfedge
		end
		# debugger
		left_point.halfedge = Halfedge.new event.center
		if (left_point == arc.parent)
			left_point.parent.left = right_point.right if right_point.parent.left == right_point
			left_point.parent.right = right_point.right if right_point.parent.right == right_point
			left_arc.right_point = left_point
			right_arc.left_point = left_point
			left_point.right_arc = right_arc.value
			left_point.change_type !left_point.right?
		elsif (right_point == arc.parent)
			right_point.parent.left = right_point.right if right_point.parent.left == right_point
			right_point.parent.right = right_point.right if right_point.parent.right == right_point
			left_arc.right_point = left_point
			right_arc.left_point = left_point
			left_point.right_arc = right_arc.value
			left_point.change_type !left_point.right?
		end
	end

	def add_arc value
		unless @root
			@root = Arc.new value
			@root
		else
			i = @root
			until i.leaf?
				# debugger
				i = (value.x < i.value.x) ? i.left : i.right
			end
			# b1, b2 = Site.find_intersection value, i.value
			# debugger
			s1 = i
			s2 = Arc.new value
			if (s1.value.x > s2.value.x)
				# debugger
				bp1 = Breakpoint.new s1.value, s2.value, false
				bp2 = Breakpoint.new s2.value, s1.value, true
				s1b = Arc.new s1.value, s1.left_point, bp1, s1.name
				s2.right_point = bp2
				s2.left_point = bp1
				s1.left_point = bp2
				if (s1.parent)
					# debugger
					s1.parent.left = bp2 if (s1.parent.left == s1)
					s1.parent.right = bp2 if (s1.parent.right == s1)
				else
					self.root = bp2
				end
				bp1.left = s1b
				bp1.right = s2
				bp2.left = bp1
				bp2.right = s1
			else
				# debugger
				bp1 = Breakpoint.new s1.value, s2.value, false
				bp2 = Breakpoint.new s2.value, s1.value, true
				s1b = Arc.new s1.value, s1.left_point, bp1, s1.name
				s2.right_point = bp2
				s2.left_point = bp1
				s1.left_point = bp2
				if (s1.parent)
					# debugger
					s1.parent.left = bp1 if (s1.parent.left == s1)
					s1.parent.right = bp1 if (s1.parent.right == s1)
				else
					self.root = bp1
				end
				bp1.left = s1b
				bp1.right = bp2
				bp2.left = s2
				bp2.right = s1
			end
			s2
		end
	end

	def draw_beachline root, c
  		return unless root
  		draw_beachline root.left, c
  		# puts "#{root.name}" if (root.name)
  		if (root.class == Arc)
  			# debugger if root.name == "A4"
  			draw_parabola Coord.new((root.left_point) ? root.left_point.value.x : -10, @@sweepline), Coord.new((root.right_point) ? root.right_point.value.x : 510, @@sweepline), root.value.center, c
  			c.stroke_width 1
  			c.text root.value.center.x, root.value.center.y - 20, root.name
  		elsif (root.class == Breakpoint)
  			draw_point root.value, c
  			c.stroke_width 1
  			c.text root.value.x, root.value.y - 20, root.name
  		end
  		draw_beachline root.right, c
	end

	def inorder root
		# debugger
		return unless root
  		inorder root.left
  		if (root.class == Breakpoint)
  			puts root.name
  			root.value
			left_arc = root.left_arc
			right_arc = root.right_arc
			if (left_arc.halfedge)
				i = left_arc.halfedge
				if (i.next)
					begin
						i = i.next
					end while i
				end
				debugger if i == root.halfedge
				i.next = root.halfedge
			else
				# debugger
				left_arc.halfedge = root.halfedge
			end
			if (right_arc.halfedge)
				i = right_arc.halfedge
				if (i.next)
					begin
						i = i.next
					end while i
				end
				debugger if i == root.halfedge
				i.next = root.halfedge
			else
				# debugger
				right_arc.halfedge = root.halfedge
			end
  		end
  		inorder root.right
  	end	

	def postorder root
		return unless root
  		postorder root.left
  		postorder root.right
  		puts "#{root.name}" if (root.name)
  	end

  	def print r, l
		return unless r
		print r.right, l + 1
		s = ""
		l.times { s += " " }
		m = ""
		m = "[#{r.left_point.name if (r.left_point)},#{r.right_point.name if (r.right_point)}]" if (r.class == Arc)
		puts "#{s}#{r.name}" + m
		print r.left, l + 1
	end

	def arc_array
		a = []
		find_arc_inorder @root, a
		a
	end

	def find_arc_inorder root, a
		return unless root
  		find_arc_inorder root.left, a
  		if (root.class == Arc)
  			a << root
  			# puts root.name
  		end
  		find_arc_inorder root.right, a
	end

	def remove_circle_events eq
		i = eq.current
		if (i)
			begin
				if i.class == CircleEvent
					eq.rm_event i
				end
				i = i.next
			end while i
		end
	end

	def check_circle eq
		remove_circle_events eq
		a = arc_array
		already_added_events = []
		while a.take(3).length > 2
			# debugger
			c = a.take 3
			ll = c.each.collect {|s| s.name}
			ll.sort!
			if (c[0].name == c[2].name || already_added_events.index(ll) || @@last_added == c[1].name)
				# debugger
				# debugger if (a[0].name == "A1")
				a.delete_at 0
				next
			end
			puts "#{c[0].name} #{c[1].name} #{c[2].name}"
			x1 = c[0].value.x.to_f
			y1 = c[0].value.y.to_f
			x2 = c[1].value.x.to_f
			y2 = c[1].value.y.to_f
			x3 = c[2].value.x.to_f
			y3 = c[2].value.y.to_f
			ab = Matrix[ [ x1, y1, 1 ], [ x2, y2, 1 ], [ x3, y3, 1 ] ]
			cb = Matrix[ [ - x1 ** 2 - y1 ** 2 ], [ - x2 ** 2 - y2 ** 2 ], [ - x3 ** 2 - y3 ** 2 ] ]
			x = ab.inverse * cb
			x0 = - x[0, 0].to_f / 2
			y0 = - x[1, 0].to_f / 2
			r = Math.sqrt( x[0, 0].to_f ** 2 + x[1, 0].to_f ** 2 - 4 * x[2, 0].to_f ) / 2
			# d = Magick::Draw.new
			# d.stroke 'blue'
			# d.stroke_width 3
			# d.stroke_dasharray 10, 10
			# d.fill 'transparent'
			# d.circle x0, y0, x0, y0 + r
			# d.draw Site.canvas
			# debugger if (a[0].name == "A1")
			a.delete_at 0
			eq.add_event CircleEvent.new c[0], c[1], c[2], Coord.new(x0, y0 + r), Coord.new(x0, y0) if (@@sweepline < y0 + r - 1e-8)
			already_added_events << ll
		end
		# debugger
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
	c.stroke "black"
	c.stroke_width 1
	c.circle a.x, a.y, a.x - 5, a.y
end

def draw_parabola a, b, c, dr # a, b – directrix points, c – focus, dr – Magick::Draw
	# debugger
	ab = MVector.new a, b
	ac = MVector.new a, c
	bc = MVector.new b, c

	n = ( ac.x ** 2 + ac.y ** 2 ) / ( 2.0 * ( ab.x * ac.y - ab.y * ac.x ) )
	d = Coord.new a.x - ab.y * n, a.y + ab.x * n

	n = ( bc.x ** 2 + bc.y ** 2 ) / ( 2.0 * ( ab.x * bc.y - ab.y * bc.x ) )
	e = Coord.new b.x - ab.y * n, b.y + ab.x * n

	f = Coord.new 0.5 * ( a.x + c.x ), 0.5 * ( a.y + c.y )
	g = Coord.new 0.5 * ( b.x + c.x ), 0.5 * ( b.y + c.y )

	n = ( ( g.x - f.x ) * ac.x + ( g.y - f.y ) * ac.y ) / ( bc.y * ac.x - bc.x * ac.y )
	h = Coord.new g.x - bc.y * n, g.y + bc.x * n

	dr.fill "black"
	dr.stroke "black"
	dr.stroke_width 1

	draw_point c, dr

	dr.fill "transparent"
	dr.stroke "red"
	dr.stroke_width 3

	dr.path "M#{d.x},#{d.y} Q#{h.x},#{h.y} #{e.x},#{e.y}"
end

def main i=1
	# sites = [Site.new(200, 50), Site.new(350, 150), Site.new(250, 300)]
	sites = [Site.new(200,50), Site.new(100,100), Site.new(400,200), Site.new(300,350)]
	eq = EventQueue.new
	t = Tree.new
	sites.each do |s|
		eq.add_event SiteEvent.new s
	end
	# debugger
	@@halfedges = []
	begin
		p = eq.pop
		@@sweepline = p.y
		if (p.class == SiteEvent)
			new_arc = t.add_arc p.site
			@@last_added = new_arc.name
			# t.print t.root, 0
			# puts "================="
			t.check_circle eq
			# puts "_________________"
		elsif (p.class == CircleEvent)
			t.rm_arc p
			t.check_circle eq
			# t.print t.root, 0
			# puts "================="
		end
		# debugger
	end while eq.current
	@@sweepline = 500
	t.finish_edges
	d = Magick::Draw.new
	# debugger 
	t.draw_beachline t.root, d
	d.path "M0,#{@@sweepline} h500"
	sites.each do |s|
		# debugger
		if (s.halfedge)
			debugger
			l = s.halfedge
			d.path "M#{s.halfedge.vertex.x},#{s.halfedge.vertex.y} L#{s.halfedge.end.x},#{s.halfedge.end.y}"
			while l.next
				l = l.next
				debugger if l == l.next
				d.path "M#{l.vertex.x},#{l.vertex.y} L#{l.end.x},#{l.end.y}"
				puts "M#{l.vertex.x},#{l.vertex.y} L#{l.end.x},#{l.end.y}"
			end
		end
	end
	d.draw Site.canvas
	Site.save "jpeg:image1"
	`open image1`
end


# (130..300).each {|i| main i}
main