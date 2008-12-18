##
# This is application setup, execution, and some app level helpers.

# hack to get rid of "warning: Object#id will be deprecated; use Object#object_id" messages
Object.send(:undef_method, :id) if Object.respond_to?(:id)

##
# define filesystem environment
APP_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..'))
DATA_DIR = File.join(APP_DIR, 'data', APP)
LIB_DIR = File.join(APP_DIR, 'lib')
IMAGE_DIR = File.join(DATA_DIR, 'images')
ICON_DIR = File.join(LIB_DIR, 'icons')
REPORT_DIR = File.join(APP_DIR, 'reports')
DB_NAME = File.join(DATA_DIR, "#{APP}.db")
Log4r::Logger[APP].info "Database name: #{DB_NAME}"
File.mkdirs DATA_DIR

##
# require all of the source files in the MVC directories
%w(models controllers views).each do |path|
  # add to load path
  lib_path = File.expand_path(File.join(LIB_DIR, path))
  lib_path.gsub!("#{APP_DIR}/", '')
  Log4r::Logger[APP].debug{"adding lib path: #{lib_path}"}
  $: << lib_path

  # require all *.rb files in these directories
  Dir.glob("#{lib_path}/*.rb").each do |filespec|
    file = File.basename(filespec, '.rb')
    Log4r::Logger[APP].info{"require #{file}"}
    require file
  end
end


# == Synopsis
# Initialize and run the application
#
# == Usage
# ui = App.new
# ui.execute
#
class App
  include Singleton

  attr_accessor :name, :description, :version, :license, :authors, :images

  ##
  # create class methods for accessing singleton instance methods.
  # this allows you to access these variables like:
  #   App.name
  # instead of
  #   App.instance.name
  class << self
    def instance_attr_accessor(name)
      class_eval "def self.#{name}; instance.#{name} end"
    end
  end

  ##
  # App.name [String] the application's name
  instance_attr_accessor :name
  instance_attr_accessor :description
  instance_attr_accessor :version
  instance_attr_accessor :license
  instance_attr_accessor :authors
  instance_attr_accessor :images

  ##
  # main error method.  Will popup a message dialog if the UI is running.
  # Regardless, it will log the error to the logger.
  #
  # == Usage
  # App.error(eMsg,msg)
  #
  # @param [Exception] eMsg optional exception
  # @param [String] msg optional message string
  def self.error(eMsg=nil, msg=nil)
    buffer = []
    buffer << 'The application has encountered an unexpected problem'
    unless msg=nil?
      buffer << msg
    end
    unless eMsg.nil?
      Log4r::Logger[APP].error "Error: #{eMsg.to_s} - #{eMsg.backtrace.join("\n")}"
      buffer << eMsg.to_s
    end
    unless MainWindow.instance.nil?
      dialog = Gtk::MessageDialog.new(MainWindow.instance, Gtk::Dialog::DESTROY_WITH_PARENT,
                                Gtk::MessageDialog::WARNING,
                                Gtk::MessageDialog::BUTTONS_CLOSE,
                                buffer.join(' - '))
      dialog.window_position = Gtk::Window::POS_CENTER_ON_PARENT
      dialog.run
      dialog.destroy
    end
  end

  ##
  # backup the database
  # TODO: needs some more robustness
  def self.backup_database
    backup_name = DB_NAME + '.backup'
    Status.status(" Backing up the database to #{backup_name}", true) do
      tmp_name = DB_NAME + '.tmp'
      File.delete tmp_name if File.exist? tmp_name
      File.rename(backup_name, tmp_name) if File.exist? backup_name
      # `sqlite3 database.db .dump | sqlite3 backup.db`
      `sqlite3 #{DB_NAME} .dump | sqlite3 #{backup_name}`
    end
  end

  ##
  # give the Gtk event loop some time
  def self.be_nice
    while Gtk.events_pending?
      Gtk.main_iteration
    end
  end

  ##
  # Change the application's mouse cursor to a busy cursor while the given block executes.
  # Will still call the block even if the UI isn't running.
  #
  # @yield [] code block to execute while the cursor is busy
  def self.busy(&block)
    # ok, most widgets respect their parent window's cursor so we start with
    # setting the cursor on the application's window.
    # Unfortunately widgets that normally change the cursor (TextView, Entry)
    # don't respect their parent's cursor, so we have to find them and change
    # them directly.
    # TODO: Entry.window.cursor does not work.  Not sure how to change the
    # cursor for an Entry widget.
    busy_cursor = Gdk::Cursor.new(Gdk::Cursor::WATCH)
    no_app_window = (MainWindow.instance.nil? ||
                     MainWindow.instance.window.nil? ||
                     MainWindow.instance.window.window.nil?)
    Log4r::Logger[APP].debug{"no_app_window => #{no_app_window}"}
    unless no_app_window
      MainWindow.instance.window.window.cursor = busy_cursor
      text_view_windows = set_textview_children_cursor(busy_cursor)
      entry_windows = set_entry_children_cursor(busy_cursor)
      # allow the system to update the cursor
      Gdk::Display.default.sync

      # call the busy block
      block.call

      # unreference the cursors by setting them to nil
      MainWindow.instance.window.window.cursor = nil
      text_view_windows.each { |win| win.cursor = nil }
      entry_windows.each { |win| win.cursor = nil }

      # allow the system to update the cursor
      Gdk::Display.default.sync
    else
      # call the busy block
      block.call
    end
  end

  ##
  # Profiles the given block if the environment variable 'PROFILE' is set to 'ON'.
  # Reports are placed in ./profile directory
  def self.profile(&block)
    RubyProf.start if ENV['PROFILE'] == 'ON'
    block.call
    if ENV['PROFILE'] == 'ON'
      result = RubyProf.stop
      gen_profile_reports(result)
    end
  end

  ##
  # App.setup(options)
  # yes, you really want to override the options as the defaults
  # are probably not what you want. :)
  #
  # @param [Hash] options contains the Application constants:
  #               :name => String, :version=>String, :license=>String, :description=>String, :authors=>[String,], :images=>[String,]}
  def self.setup(options={})
    instance.name = options[:name] || 'My App'
    instance.version = options[:version] || '0.0.1'
    instance.license = options[:license] || 'public domain'
    instance.description = options[:description] || 'The greatest application in the universe.'
    instance.authors = options[:authors] || ['HAL 9000', 'C-3PO']
    instance.images = options[:images] || []
    Gtk.init
    MainController.instance.init
  end

  def self.execute
    instance.execute
  end

  ##
  # run the application
  def execute
    status = Status.new('Application')
    status.push(' Initializing...')
    MainController.instance.execute
    Gtk.main
  end

  protected

  def initialize
    # load any initial data
    Database.instance.setup
  end

  def self.gen_profile_reports(result)
    # Print a flat profile to text
    File.mkdirs REPORT_DIR
    profile_report('flat', result)     {|result| RubyProf::FlatPrinter.new(result)}
    profile_report('graph', result)    {|result| RubyProf::GraphPrinter.new(result)}
    profile_report('calltree', result) {|result| RubyProf::CallTreePrinter.new(result)}
  end

  def self.profile_report(name, result, &block)
    filename = File.join(REPORT_DIR, name + '.profile')
    Log4r::Logger[APP].info {"Generating profile report: #{filename}"}
    File.delete filename if File.exist?(filename)
    File.open(filename, 'w') do |file|
      printer = block.call(result)
      printer.print(file, 0)
    end
  end

  def self.set_textview_children_cursor(busy_cursor)
    # handle TextView child widgets
    # note, text_view.get_window(Gtk::TextView::WINDOW_TEXT) => Gdk::Window
    text_views = get_textview_children(MainWindow.instance.window)
    text_view_windows = text_views.collect { |text_view| text_view.get_window(Gtk::TextView::WINDOW_TEXT) }.compact.uniq
    text_view_windows.each { |win| win.cursor = busy_cursor }
    text_view_windows
  end

  def self.set_entry_children_cursor(busy_cursor)
    # handle Entry child widgets
    # note, entry.window => Gdk::Window and entry.children => [Gdk::Window]
    entries = get_entry_children(MainWindow.instance.window)
    entry_windows = entries.collect { |entry| entry.window }.compact.uniq
    child_entry_windows = []
    entry_windows.each do |ew|
      child_entry_windows += ew.children.select{|c| c.kind_of? Gdk::Window}
    end
    entry_windows += child_entry_windows
    entry_windows.compact!
    entry_windows.uniq!
    entry_windows.each { |win| win.cursor = busy_cursor }
    entry_windows
  end

  def self.get_textview_children(container)
    tv_children = []
    tv_children += container.children.select {|child| child.kind_of? Gtk::TextView}
    container_children = container.children.select {|child| child.kind_of? Gtk::Container}
    tv_children += container_children.collect{ |child| get_textview_children(child) }
    tv_children.flatten.uniq
  end

  def self.get_entry_children(container)
    entry_children = []
    entry_children += container.children.select {|child| child.kind_of? Gtk::Entry}
    container_children = container.children.select {|child| child.kind_of? Gtk::Container}
    entry_children += container_children.collect{ |child| get_entry_children(child) }
    entry_children.flatten.uniq
  end

end
