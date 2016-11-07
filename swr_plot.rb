require 'gtk2'

class SwrPlot < Gtk::DrawingArea
  attr_accessor :data
  attr_accessor :start_frequency, :end_frequency
  attr_accessor :low_value, :high_value

  def initialize
    super
    @data= []

    @start_frequency= 1e6
    @end_frequency= 30e6
    @frequency_step= 1e6

    @low_value= 0
    @high_value= 1024
    @value_step= 128
  end
  
  def connect
    set_size_request(256,192)
    signal_connect("expose_event") {redraw}
  end

  def redraw
    gc= Gdk::GC.new(window)
    cr= window.create_cairo_context

    gc.rgb_fg_color= Gdk::Color.new(65535, 65535, 65535);
    window.draw_rectangle(gc, true, 
                          0, 0, allocation.width, allocation.height) 
    x_scale= allocation.width.to_f / (@end_frequency - @start_frequency)
    y_scale= allocation.height.to_f / (@high_value - @low_value)

    gc.rgb_fg_color= Gdk::Color.new(50000, 50000, 50000)

    value_line= @low_value
    while value_line < @high_value do
      y= allocation.height - (value_line - @low_value) * y_scale;
      window.draw_line(gc, 0, y, allocation.width, y)
      cr.move_to(10, y-10);
      cr.show_text(value_line.to_s)
      value_line += @value_step
    end

    frequency_line= @start_frequency
    while frequency_line < @end_frequency do
      x= (frequency_line - @start_frequency) * x_scale;
      window.draw_line(gc, x, 0, x, allocation.height)
      cr.move_to(x+10, allocation.height - 10);
      cr.show_text((frequency_line/1e6).to_s)
      frequency_line += @frequency_step
    end

    gc.rgb_fg_color= Gdk::Color.new(0, 0, 0)
    scaled_points= @data.map do |point|
      [(point[0] - @start_frequency) * x_scale,
       allocation.height - (point[1] - @low_value) * y_scale]
    end
    window.draw_lines(gc, scaled_points)
  end
end
