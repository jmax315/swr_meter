require "gtk2"
require "rubyserial"
require_relative "swr_plot"

class MainWindow < Gtk::Window
  def initialize
    super
    @measure_button= Gtk::Button.new("Measure")
    @swr_bridge_port= "/dev/ttyUSB0"
    @plot= SwrPlot.new
  end
  
  def connect
    main_box= Gtk::VBox.new
    add(main_box)

    buttons= Gtk::HButtonBox.new
    buttons.pack_start(@measure_button)
    main_box.pack_start(buttons, false)

    main_box.pack_start(@plot, true)
    @plot.connect

    signal_connect('delete_event') { false }
    signal_connect('destroy') { Gtk.main_quit }

    @measure_button.signal_connect('clicked') {measure}
  end

  def measure
    swr_bridge= Serial.new(@swr_bridge_port, 115200)
    frequency= @plot.start_frequency
    step= (@plot.end_frequency - @plot.start_frequency)/100;
    frequency_done= true
    GLib::Idle.add do
      if frequency_done
        frequency += step
        frequency_done= false
        swr_bridge.write((frequency/1000).to_i)
        raw_data= ""
        GLib::Idle.add do
          raw_data += swr_bridge.read(100)
          frequency_done= raw_data[-4..-1] == "\r\n\r\n"
          if frequency_done
            update_plot(raw_data)
          end
          !frequency_done
        end
      end
      frequency < @plot.end_frequency
    end
  end

  def update_plot(raw_data)
    raw_data= raw_data[0..-5]
    n= 0
    sum= 0
    frequency= 0
    raw_data.split("\n").each do |line|
      line.strip!
      frequency, value = line.split(',').map(&:to_f)
      sum += value
      n += 1
    end
    @plot.data << [frequency, sum/n];
    @plot.queue_draw_area(0, 0, 10000, 10000)
  end
end
