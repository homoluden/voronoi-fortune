
require 'WindowsBase'
require 'PresentationCore'
require 'PresentationFramework'
require 'System.Windows.Forms'
require 'System.Core'


include System::Windows::Media
include System::Windows
include System::Windows::Controls

WIN_W = 640
WIN_H = 480

MID_X = WIN_W / 2
MID_Y = WIN_H / 2

@@window = System::Windows::Window.new
@@window.background = System::Windows::Media::Brushes.LightGray


@@canvas = System::Windows::Controls::Canvas.new
@@canvas.width = WIN_W
@@canvas.height = WIN_H

@@window.content = @@canvas

def clear_canvas
	@@canvas.children.clear
end

def create_polygon(vertices)

	poly = System::Windows::Shapes::Polygon.new
	poly.points = PointCollection.new
	
	vertices.each{|v| poly.points << (Point.new  v.x+MID_X, MID_Y - v.y)}
	
	poly.stroke = Brushes.black
	poly.stroke_thickness = 0.5
	
#Canvas.set_left poly, 0
	#Canvas.set_top poly, 0
	
	poly
		
end


def create_circle(center, radius)

	poly = System::Windows::Shapes::Ellipse.new
	poly.width = poly.height = radius
	
	poly.stroke = Brushes.black
	poly.stroke_thickness = 0.5
	
	poly.fill = Brushes.sky_blue
	
	Canvas.set_left poly, center.x+MID_X
	Canvas.set_top poly, MID_Y-center.y
	
	poly
		
end


def app_start
  app = System::Windows::Application.new
  
  app.run @@window
end
