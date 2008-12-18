
# == Synopsis
# Menu bar widget
class Menus
  include Singleton

  UI_DEF =
'<ui>
  <menubar>
    <menu name="FileMenu" action="FileMenuAction">
      <menuitem name="New" action="NewAction" />
      <menuitem name="Edit" action="EditAction" />
      <menuitem name="Copy" action="CopyAction" />
      <menuitem name="Delete" action="DeleteAction" />
      <separator/>
      <menuitem name="Quit" action="QuitAction" />
    </menu>
    <menu name="Options" action="OptionsAction">
      <menuitem name="OptionOne" action="OptionOneAction" />
      <menuitem name="OptionTwo" action="OptionTwoAction" />
    </menu>
    <menu name="Popup" action="PopupAction">
      <menuitem name="PopupSelect" action="SelectAction" />
    </menu>
    <menu name="HelpMenu" action="HelpMenuAction">
      <menuitem name="About" action="AboutAction" />
    </menu>
  </menubar>
  <popup name="main_content">
    <menuitem name="New" action="NewAction" />
    <menuitem name="Edit" action="EditAction" />
    <menuitem name="Copy" action="CopyAction" />
    <menuitem name="Delete" action="DeleteAction" />
  </popup>
  <toolbar action="toolbarAction">
    <placeholder name="JustifyToolItems">
      <separator/>
      <toolitem name="New" action="NewAction" />
      <toolitem name="Edit" action="EditAction" />
      <toolitem name="Copy" action="CopyAction" />
      <toolitem name="Delete" action="DeleteAction" />
      <separator/>
      <toolitem name="OptionOne" action="OptionOneAction" />
      <toolitem name="OptionTwo" action="OptionTwoAction" />
      <separator/>
      <toolitem name="PopupSelect" action="SelectAction" />
      <separator/>
    </placeholder>
  </toolbar>
</ui>'
  
  def initialize()
    super()
    @logger = Log4r::Logger[APP]
  end
  
  def create_menus(window, &on_activate)
    @window = window
    @on_activate = on_activate

    global_entries = [
      ['FileMenuAction', nil, '_File',    nil, nil, nil, nil],
      ['CopyMenuAction', nil, '_Copy',    nil, nil, nil, nil],
      ['OptionsAction', nil,  '_Options', nil, nil, nil, nil],
      ['PopupAction', nil,    '_Popup',   nil, nil, nil, nil],
      
      ['HelpMenuAction', nil,            '_Help', nil, nil, nil, nil],
      ['AboutAction', Gtk::Stock::ABOUT, '_About', nil, 'Information about the application', Proc.new{on_about_activate()}]
    ]
    
    global_action_group = Gtk::ActionGroup.new('GlobalActionGroup')
    global_action_group.add_actions(global_entries)

    selected_action_group = Gtk::ActionGroup.new('SelectedActionGroup')
    
    @ui = Gtk::UIManager.new
    @ui.add_ui(UI_DEF)
    @ui.insert_action_group(global_action_group,0)
    @ui.insert_action_group(selected_action_group,0)

    @realized = false
  end

  def get_action_group(name)
    @ui.action_groups.select{|a| a.name == name}[0]
  end
  
  def get_menubar
    realize()
    @ui.get_toplevels(Gtk::UIManager::MENUBAR)
  end
  
  def get_toolbar
    realize()
    @ui.get_toplevels(Gtk::UIManager::TOOLBAR)
  end

  def get_popup(name)
    realize()
    @ui.get_widget("popup/#{name}")
  end

  def get_widget(name)
    realize()
    @ui.get_widget(name)
  end
  
  protected

  def realize()
    unless @realized
      @ui.ensure_update
      @window.add_accel_group(@ui.accel_group)
      @realized = true
    end
  end
  
  def on_about_activate
    Gtk::AboutDialog.show(@window,
                          :name => 'About ' + App.name,
                          :version => App.version,
                          :comments => App.description,
                          :license => App.license,
                          :authors => App.authors,
                          :program_name => App.name
                         )
  end
  
end

