# NOTE: This doesn't work:
# class Gtk::TreeModelSort
#   include Gtk::TreeDragDest
# end

##
# This is the main window for the application.
#
class MainWindow
  include Singleton

  attr_reader :window
  attr_accessor :status

  ##
  # set the application's window title
  def self.title=(title_str)
    instance.window.title = "#{App.name} - #{title_str}"
  end

  ##
  # reload the window
  def reload_window
    @logger.info("reload_window")
    # reload any sub-panels here
  end

  ##
  # simple prompt
  def prompt(title, instructions, default_value)
    value = nil
    running = true
    dialog = PromptDialog.new(title, @window, instructions, default_value)
    dialog.signal_connect('response') do |dlg, response_id|
      if response_id == Gtk::Dialog::RESPONSE_ACCEPT
        value = dialog.value
      end
      dlg.destroy
      running = false
    end
    dialog.show_all
    begin
      App.be_nice
    end while running
    value
  end

  ##
  # save the window position when the app is closing
  def on_delete_event
    width, height = @window.window.size
    @logger.debug{"window size => #{width}, #{height}"}
    unless width <= 0 || height <= 0
      Configuration.set(Configuration::APP_SIZE_WIDTH, width)
      Configuration.set(Configuration::APP_SIZE_HEIGHT, height)
    end
    x,y = @window.window.root_origin
    x = -1 if x < 0
    y = -1 if y < 0
    @logger.debug{"window position => #{x}, #{y}"}
    Configuration.set(Configuration::APP_POSITION_X, x)
    Configuration.set(Configuration::APP_POSITION_Y, y)
    false
  end

  protected

  def initialize
    @logger = Log4r::Logger[APP]

    # set the default icons for all windows
    Gtk::Window.default_icon_list = App.images.collect do |name|
      filespec = File.join(ICON_DIR, name)
      Gtk::Image.new(filespec).pixbuf
    end

    # setup the main application window
    @window = create_app_window

    # setup the application menu
    Menus.instance.create_menus(@window) { |name| on_menu_activate(name) }
    main_controller = MainController.instance
    main_controller.create_global_actions
    main_controller.create_selected_actions

    # create the various panels used on the main window
    create_panels

    # create menubar
    menus = Menus.instance.get_menubar
    menu_bar = Gtk::HBox.new
    menu_bar.pack_start(menus[0], true, true, 0)

    # create toolbar
    toolbars = Menus.instance.get_toolbar
    tool_bar = toolbars[0]
    tool_bar.orientation = Gtk::ORIENTATION_HORIZONTAL
    tool_bar.toolbar_style = Gtk::Toolbar::Style::ICONS

    @status = Status.new('MainWindow')

    # assemble the window
    vbox = Gtk::VBox.new(false, 1)
    vbox.pack_start(menu_bar, false, true, 1)
    vbox.pack_start(tool_bar, false, false)
    vbox.pack_start(content, true, true, 1)
    vbox.pack_start(Status.statusbar, false, false)
    @window.add vbox

    @window.show_all
  end

  def create_app_window
    window = Gtk::Window.new(App.name)
    width = Configuration.get(Configuration::APP_SIZE_WIDTH, '1024').to_i
    height = Configuration.get(Configuration::APP_SIZE_HEIGHT, '600').to_i
    @logger.info("width=>#{width}, height=>#{height}")
    window.set_default_size(width, height)
    x = Configuration.get(Configuration::APP_POSITION_X, '-1').to_i
    y = Configuration.get(Configuration::APP_POSITION_Y, '-1').to_i
    unless x < 0 || y < 0
      window.move x,y
    end
    window.border_width=( 5 )
    window.signal_connect("destroy") { @logger.info{"destroy"}; Gtk.main_quit }
    window.signal_connect("delete_event") { on_delete_event }
    window
  end

  ##
  # create any sub-panels
  def create_panels
    @main_panel = Gtk::Frame.new
  end

  # layout the panels
  def content
    vbox = Gtk::VBox.new
    vbox.pack_start(@main_panel, true, true)
    vbox
  end
  
end

