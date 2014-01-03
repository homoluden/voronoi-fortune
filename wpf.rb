
require 'vor'

require 'WindowsBase'
require 'PresentationFramework'
require 'PresentationCore'
require 'System.Core'

WIN_W = 640
WIN_H = 480

def create_triangle(v1, v2, v3)
	include System::Windows::Media
	include System::Windows

	poly = System::Windows::Shapes::Polygon
	poly.points = PointCollection.new
	poly.points << (Point.new  v1.x, v1.y)
	poly.points << (Point.new  v2.x, v2.y)
	poly.points << (Point.new  v3.x, v3.y)
	
	poly.stroke = Brushes.black
	poly.strole_thickness = 0.5
	
	poly
		
end

def show_map
	@window = System::Windows::Window.new
	@window.background = System::Windows::Media::Brushes.LightGray
	@window.width = WIN_W
	@window.height = WIN_H

	@canvas = System::Windows::Controls::Canvas.new

	@window.content = @canvas

	app = System::Windows::Application.new
	app.run(@window)
end

generate_vor

