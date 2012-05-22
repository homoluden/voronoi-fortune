require "rubygems"
require "ruby_vor"
require "pp"

points = [
  RubyVor::Point.new(120, 290),
  RubyVor::Point.new(110, 120),
  RubyVor::Point.new(160, 90.2),
  RubyVor::Point.new(3.14159265, 3.14159265)
]

# Compute the diagram & triangulation
comp = RubyVor::VDDT::Computation.from_points(points)

puts "The nearest-neighbor graph:"
pp comp.nn_graph

puts "\nThe minimum-spanning tree:"
pp comp.minimum_spanning_tree

# Just the triangulation
RubyVor::Visualizer.make_svg(comp, :name => 'tri.svg')

# Just the MST
RubyVor::Visualizer.make_svg(comp, :name => 'mst.svg', :triangulation => false, :mst => true)

# Voronoi diagram and the triangulation
RubyVor::Visualizer.make_svg(comp, :name => 'dia.svg', :voronoi_diagram => true)