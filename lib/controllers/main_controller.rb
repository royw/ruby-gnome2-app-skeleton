require 'actions'
class MainController
  include Singleton
  include Actions

  attr_accessor :selected_action_group

  def create_global_actions
    global_action_group = Menus.instance.get_action_group('GlobalActionGroup')

    add_action(global_action_group, :NewAction)    { on_new_action }
    add_action(global_action_group, :CopyAction)   { on_copy_action }
    add_action(global_action_group, :QuitAction)   { on_quit_action }
    add_action(global_action_group, :SaveAction)   { on_save_action }
    add_action(global_action_group, :OpenAction)   { on_open_action }
    add_action(global_action_group, :SelectAction) { on_select_action }

    global_action_group.add_radio_actions([radio_entry(:OptionOneAction),
                                           radio_entry(:OptionTwoAction)
                                          ]) {|action, current| on_option_action(action, current)}
  end

  def create_selected_actions
    @selected_action_group = Menus.instance.get_action_group('SelectedActionGroup')

    add_action(@selected_action_group, :EditAction) { on_edit_action }
    add_action(@selected_action_group, :DeleteAction) { on_delete_action }
    add_action(@selected_action_group, :CopyAction) { on_copy_action }
  end

  ##
  # reload 
  def reload
    @logger.info{"reload"}
    MainWindow.instance.reload_window
    @status.replace('Ready')
    # load application data here

    # a good place to update the application title
    # MainWindow.title='foo bar'
  end

  def init
    MainWindow.instance
    @status = Status.new("MainController")
  end

  # run the application
  def execute
    App.be_nice
    reload
  end


  protected

  def radio_entry(action_key)
    name = action_key.to_s
    hash = ACTIONS[action_key]
    [name, hash[:stock], hash[:label], hash[:accel], hash[:tooltip], hash[:value]]
  end

  def add_action(action_group, action_key, &block)
    @logger.info {"add_action(action_group, #{action_key}, &block)"}
    name = action_key.to_s
    hash = ACTIONS[action_key]
    if hash.nil?
      @logger.error{"Can not add_action: Missing action_key #{action_key}"}
    else
      action = create_action(name, hash[:label], hash[:tooltip], hash[:stock], &block)
      action_group.add_action(action, hash[:accel])
      # need to keep an instance of the action around so it doesn't get garbage collected
      @@actions_cache ||= []
      @@actions_cache << action
    end
  end

  def initialize
    @logger = Log4r::Logger[APP]
    @provider_set = nil
  end

  def create_action(name, label, tooltip, stock, &block)
    action = Gtk::Action.new(name, label, tooltip, stock)
    action.signal_connect('activate', &block)
    action
  end

  def on_new_action
    @logger.warn{"TODO: code for new"}
    reload
  end

  def on_edit_action
    @logger.warn{"TODO: code for edit"}
    reload
  end

  def on_delete_action
    @logger.warn{"TODO: code for delete"}
    reload
  end

  def on_copy_action
    @logger.warn{"TODO: code for copy"}
    set_clipboard_text('foo bar')
  end

  def set_clipboard_text(str)
    # default system clipboard (the only clipboard on windows)
    default_clipboard = Gtk::Clipboard.get(Gdk::Display.default, Gdk::Selection::CLIPBOARD)
    default_clipboard.text = str
    # x selection clipboard
    primary_clipboard = Gtk::Clipboard.get(Gdk::Display.default, Gdk::Selection::PRIMARY)
    primary_clipboard.text = str
  end

  def on_quit_action
    MainWindow.instance.on_delete_event
    Gtk::main_quit
  end

  def on_select_action()
    # popup a menu
    create_menu_popup(['alpha', 'bravo', 'charlie']) { |widget, event| on_menu_activate(widget) }
  end

  def create_menu_popup(item_names, &block)
    menu = Gtk::Menu.new
    item_names.each do |name|
      menu_item = Gtk::MenuItem.new(name)
      menu_item.signal_connect('button-press-event', block)
      menu.append(menu_item)
    end
    menu.show_all
    event = Gdk::EventButton.new(Gdk::Event::BUTTON_PRESS)
    menu.popup(nil, nil, event.button, event.time)
  end

  def on_menu_activate(menu_item)
    name = menu_item.child.label
    App.busy do
      Status.status("Switching to #{name}", true) do
        # code to respond to menu items
        sleep 2
        reload
      end
    end
  end

  def on_save_action
    @logger.warn{"TODO: code for save"}
  end

  def on_load_action
    @logger.warn{"TODO: code for load"}
  end

  def on_option_action(action, current)
    App.busy do
      Status.status("Switching to #{current.label.to_s}", true) do
        # code to respond to menu items
        sleep 2
        reload
      end
    end
  end
  
end
