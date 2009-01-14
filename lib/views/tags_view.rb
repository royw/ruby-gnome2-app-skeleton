#!/usr/bin/env ruby

require 'rubygems'
require 'gtk2'
require 'log4r'

# == Synopsis
# This class implements a tag UI widget.
#
# == Details
# The tags will be shown using a flow layout with auto wrapping.
#
# The tags will be enlarged and bolded when the tag is asserted
# and normal size when the tag is deasserted.
#
# A popup menu supports adding, renaming, and deleting tags.
#
# A 'changed' signal is emitted when the tag's state or composition
# changes.  The 'changed' signal's parameters are:
#   states => Hash, {tag_name => TrueClass/FalseClass}
#   command => Symbol, one of the following:
#      :new            - a new tag was added
#      :rename         - a tag was renamed
#      :delete         - a tag was deleted
#      :update_states  - the user selected or deselected a tag
#   old_name => String, old tag name
#   new_name => String, new tag name
#
# The command and valid parameters combinations are:
# :new, new_name, states
# :rename, old_name, new_name, states
# :delete, old_name, states
# :update_states, states
#
# == Usage
# See demo at end of this file.
#

class TagsView < Gtk::EventBox
  type_register
  
  CHANGED = 'changed'

  signal_new(CHANGED,                    # name
             GLib::Signal::RUN_FIRST,    # flags
             nil,                        # accumulator (XXX: not supported yet)
             nil,                        # return type (void == nil)
             Hash, Symbol                # parameter types: states, command
             )
  # needed to be able to emit the "changed" signal
  def signal_do_changed(states, command)
  end

  attr_accessor :edit_panel
  
  SHOW_TOOLTIP = "Left click to toogle tag state."
  EDIT_TOOLTIP = SHOW_TOOLTIP + "\nRight click for editing menu."
  
  def initialize(window, tag_states=nil, editable=false, spacing=5)
    super()
    @window = window
    @logger = Log4r::Logger[APP]
    @loading = false
    
    @tags_editable = editable
    @tag_spacing = spacing
    @tag_anchors = {}

    @tag_textview = create_tag_textview

    @popup_menu = TagsView::create_popup_menu(self, @tags_editable)

    hbox = Gtk::HBox.new
    hbox.pack_start(@tag_textview, true, true, 5)
    add hbox
    
    set_tags(tag_states) unless tag_states.nil?
    
    # set the background color of the TextView to be the window's
    # background color
    window.realize
    org_bg = window.style.bg(Gtk::STATE_NORMAL)
    @tag_textview.modify_base(Gtk::STATE_NORMAL, org_bg)
    
    # start with the edit panel hidden
    self.signal_connect('show') do |panel|
      @tag_anchors.each do |name, props|
        props[:widget].show_label
      end
      win = @tag_textview.get_window(Gtk::TextView::WINDOW_TEXT)
      win.cursor = nil unless win.nil?
    end
  end

  def setup_drop(status, status_msg, &block)
    DropController.setup_drop(@tag_textview, status, status_msg, &block)
  end

  # returns a Hash with tag name as key and tag state (true/false) as value
  def tag_states()
    states = {}
    @tag_anchors.each do |tag_name, tag_props|
      widget = tag_props[:widget]
      states[tag_name] = widget.active?
    end
    states
  end
  
  # tag_states is a Hash with tag name as key and tag state (true/false) as value
  def set_tags(states, do_emit=true)
    old_states = tag_states()
    old_names = old_states.keys
    new_names = states.keys
    intersection = old_names & new_names

    missing_names = new_names - intersection
    extra_names = old_names - intersection

    missing_names.sort.each{ |name| insert_tag(name) }
    extra_names.each{ |name| delete_tag(name) }
    
    new_names.each do |name|
      activate(name, states[name])
    end
    signal_emit(CHANGED, tag_states(), :update_states) if do_emit
  end
  
  # create the edit tag popup menu
  # TODO: replace ItemFactory (deprecated)
  def self::create_popup_menu(widget, editable)
    # menu_items => [ [path, item_type, accelerator, extra data (stock), proc, data] ]
    menu_items = []
    
    if editable
      menu_items << [ '/_New Tag', Gtk::ItemFactory::ITEM, nil, Gtk::Stock::NEW, Proc.new{widget.on_menu(:new)} ]
      if widget.kind_of? TagButton
        menu_items << [ '/_Rename Tag', Gtk::ItemFactory::ITEM, nil, Gtk::Stock::EDIT,   Proc.new{widget.on_menu(:rename)} ]
        menu_items << [ '/_Delete Tag', Gtk::ItemFactory::ITEM, nil, Gtk::Stock::DELETE, Proc.new{widget.on_menu(:delete)} ]
      end
      menu_items << [ '/', Gtk::ItemFactory::SEPARATOR, nil, nil, nil ]
    end
    menu_items << [ '/_Select All Tags', Gtk::ItemFactory::ITEM,      nil, Gtk::Stock::SELECT_ALL, Proc.new{widget.on_menu(:select_all)} ]
    menu_items << [ '/_Clear All Tags',  Gtk::ItemFactory::ITEM,      nil, Gtk::Stock::CLEAR,      Proc.new{widget.on_menu(:clear_all)}  ]
    
    accel_group=Gtk::AccelGroup.new
    item_factory=Gtk::ItemFactory.new(Gtk::ItemFactory::TYPE_MENU,'<tag_textview>',nil)
    item_factory.create_items(menu_items)
    return item_factory.get_widget('<tag_textview>')
  end
  
  # handle menu events
  # parses the menu command then setups up the edit panel accordingly, finally shows the edit panel
  def on_menu(command)
    @command = command.to_sym
    case @command
    when :new
      widget = insert_tag('')
      widget.rename unless widget.nil?
    when :select_all
      set_all_tags(true)
    when :clear_all
      set_all_tags(false)
    else
      @logger.error{"TagsView::on_menu - unknown menu command: #{@command}"}
    end
  end
  
  protected
  
  def create_tag_textview
    tag_buffer = Gtk::TextBuffer.new
    tag_buffer.text = ''
    tag_textview = Gtk::TextView.new tag_buffer
    tag_textview.wrap_mode = Gtk::TextTag::WRAP_WORD
    tag_textview.editable = false
    tag_textview.cursor_visible = false
    tag_textview.tooltip_text = (@tags_editable ? EDIT_TOOLTIP : SHOW_TOOLTIP)
    tag_textview.signal_connect('button_press_event') { |widget, event| on_button_pressed(widget, event) }
    tag_textview.signal_connect('popup_menu') { @popup_menu.popup(nil, nil, 0, Gdk::Event::CURRENT_TIME) if @tags_editable }

    tag_buffer.signal_connect_after('changed') do |*args|
      win = @tag_textview.get_window(Gtk::TextView::WINDOW_TEXT)
      unless win.nil?
        win.cursor = nil
      end
    end
    tag_buffer.text = ''
    tag_textview
  end

  # handle tag editing
  def on_edited(command, old_name, new_name, state)
    case command.to_sym
    when :new
      insert_tag(new_name)
      Tag.find_or_create(new_name)
    when :rename
      rename_tag(old_name, new_name, state)
      Tag.rename(old_name, new_name)
    when :delete
      delete_tag(old_name)
      Tag.delete(old_name)
    end
    signal_emit(CHANGED, tag_states(), command)
  end
  
  # insert a tag (name) into the textview.  
  # the tag must not already exist in the buffer.
  # Each tag is a TagLabel widget attached to an anchor.
  # Each anchor is placed in the text buffer followed by two spaces
  def insert_tag(name)
    widget = nil
    unless @tag_anchors.keys.include? name
      iter = nil
      
      # set iter if an existing tag can be found with a name greater 
      # than the one we are inserting
      @tag_anchors.keys.sort.each do |tag_name|
        if name.casecmp(tag_name) == -1
          iter = @tag_textview.buffer.get_iter_at_child_anchor(@tag_anchors[tag_name][:anchor])
          break
        end
      end
      
      # if we didn't find a lexigraphically greater tag, then set the iterator to
      # the end of the buffer
      if iter.nil?
        iter = @tag_textview.buffer.end_iter 
      end
      
      # create an anchor, then create the widget, then add the anchor to the 
      # buffer and finally attach the widget to the anchor
      anchor = @tag_textview.buffer.create_child_anchor(iter)
      widget = create_tag_widget(name)
      @tag_textview.add_child_at_anchor(widget, anchor)
      widget.show_all
      
      # save the widget and anchor for the tag
      @tag_anchors[name] = {:widget => widget, :anchor => anchor}
    end
    widget
  end
  
  # rename the given tag (old_name) to new_name
  # the old_name must already exist and
  # the new_name must not yet exist
  def rename_tag(old_name, new_name, state)
    if @tag_anchors.keys.include? old_name
      unless @tag_anchors.keys.include? new_name
        delete_tag(old_name)
        insert_tag(new_name)
        activate(new_name, state)
      end
    end
  end
  
  # delete the tag with the given name
  # tag must exist
  # NOTE: it might be a good idea to disconnect any signal handlers
  # from the widgets as we delete them.
  def delete_tag(name)
    if @tag_anchors.keys.include? name
      start_iter = @tag_textview.buffer.get_iter_at_child_anchor(@tag_anchors[name][:anchor])
      unless start_iter.nil?
        end_iter = start_iter.copy
        end_iter.forward_chars(1)
        unless end_iter.nil?
          @tag_textview.buffer.delete(start_iter, end_iter)
          @tag_anchors.delete(name)
        end
      end
    end
  end
  
  # sets the given tag Label state to either true/false
  def activate(tag_name, enabled)
    unless @tag_anchors[tag_name].nil?
       @tag_anchors[tag_name][:widget].activate(enabled)
    end
  end
  
  # create the tag widget
  def create_tag_widget(name)
    tag_widget = TagButton.new(@window, @tag_textview, name, @tags_editable, @tag_spacing)
    tag_widget.signal_connect(TagButton::CHANGED) { |widget, command, old_name, new_name, state| on_edited(command, old_name, new_name, state) }
    tag_widget.signal_connect(TagButton::ON_MENU) { |widget, command| on_menu(command) }
    tag_widget
  end
  
  # the user clicked on a label
  # for left mouse button, we toggle the labels assertion state
  # for right mouse button, we popup the tag editing menu
  def on_button_pressed(widget, event)
    if event.kind_of? Gdk::EventButton and event.button == 3 # right button click
      @popup_menu.popup(nil, nil, event.button, event.time)
      return true
    end
    false
  end
  
  def set_all_tags(state)
    new_states = tag_states()
    new_states.each { |name, value| new_states[name] = state }
    set_tags(new_states)
  end
  
  # == Synopsis
  # A TagButton class that works sort of like a ToggleButton but simply enlarges the
  # text to indicate asserted and reduces the text size to indicate deasserted.  There
  # is no button drawn.
  class TagButton < Gtk::EventBox
    type_register
  
    CHANGED = 'changed'
    ON_MENU = 'on_menu'
  
    signal_new(CHANGED,                        # name
              GLib::Signal::RUN_FIRST,           # flags
              nil,                               # accumulator (XXX: not supported yet)
              nil,                               # return type (void == nil)
              Symbol, String, String, TrueClass  # parameter types: command, old_name, new_name, state
              )
    
    signal_new(ON_MENU,                        # name
              GLib::Signal::RUN_FIRST,           # flags
              nil,                               # accumulator (XXX: not supported yet)
              nil,                               # return type (void == nil)
              Symbol                             # parameter types: command, old_name, new_name, state
              )
    
    def initialize(window, tag_text_view, tag_name, editable=true, spacing=5)
      super()
      @logger = Log4r::Logger[APP]
      @window = window
      @tag_text_view = tag_text_view
      @tag_name = tag_name
      @tag_editable = editable
      @tag_state = false
      
      @tag_label = Gtk::Label.new tag_name
      @tag_entry = Gtk::Entry.new
      @tag_entry.signal_connect('key-press-event') { |entry, event| on_key_pressed(entry, event) }
      
      hbox = Gtk::HBox.new
      hbox.pack_start(@tag_label, false, false, spacing)
      hbox.pack_start(@tag_entry, false, false, spacing)
      add(hbox)
      
      @popup_menu = TagsView::create_popup_menu(self, @tag_editable)
    
      self.signal_connect('button_press_event') { |widget, event| on_button_pressed(widget, event) }
      self.signal_connect('popup_menu') { @popup_menu.popup(nil, nil, 0, Gdk::Event::CURRENT_TIME) if @tag_editable }
      self.signal_connect('show') { |box| @tag_entry.hide_all }
      @tag_entry.signal_connect('show') { |entry| entry.grab_focus }
    end
    
    def show_label()
      @tag_entry.hide_all
      @tag_label.show_all
    end
    
    # set the state
    # asserted => big, bold text
    # deasserted => normal text
    def activate(state)
      @tag_state = state
      @tag_label.markup = (state ? "<big><b>#{@tag_name}</b></big>" : @tag_name)
    end
    
    # fetch the state
    def active?
      @tag_state
    end
    
    def rename
      @command = :rename
      @tag_label.hide_all
      @tag_entry.text = @tag_name
      @tag_entry.show_all
      @tag_entry.grab_focus
    end
    
    # handle menu events
    # parses the menu command then setups up the edit panel accordingly, finally shows the edit panel
    def on_menu(command)
      @command = command.to_sym
      case @command
      when :new
        @tag_entry.text = ''
        @tag_entry.show_all
        @tag_entry.grab_focus
      when :rename
        @tag_label.hide_all
        @tag_entry.text = @tag_name
        @tag_entry.show_all
        @tag_entry.grab_focus
      when :delete
        self.signal_emit(CHANGED, :delete, @tag_name, nil, nil)
      else
        self.signal_emit(ON_MENU, @command)
      end
    end
  
    protected
    
    # handle keyboard events
    # intercepts Return keypress to accept edit and Escape keypress to cancel edit.
    # on accept edit, emit the "changed" signal
    def on_key_pressed(entry, event)
      text = nil
      text = @tag_name  if event.keyval == Gdk::Keyval::GDK_Escape  # cancel edit
      text = entry.text if event.keyval == Gdk::Keyval::GDK_Return  # accept edit
      unless text.nil?
        old_name = @tag_name
        show_label
        unless @tag_name == text
          # NOTE: on :rename, this TagButton instance will be deleted, so the
          # "changed" signal emit must be the last command in this method that
          # references any instance data.
          self.signal_emit(CHANGED, @command, old_name, text, @tag_state)
        end
      end
    end
    
    # the user clicked on a label
    # for left mouse button, we toggle the labels assertion state
    # for right mouse button, we popup the tag editing menu
    def on_button_pressed(widget, event)
      if event.kind_of? Gdk::EventButton
        if event.button == 1 # left button click
          widget.activate(!@tag_state)  # toggles the state of the TagButton
          self.signal_emit(CHANGED, :update_states, nil, nil, nil)
          return true
        elsif event.button == 3 # right button click
          @popup_menu.popup(nil, nil, event.button, event.time) if @tag_editable
          return true
        end
      end
      false
    end
    
    # needed to be able to emit the "changed" signal
    def signal_do_changed(command, old_name, new_name, state)
    end
    
    # needed to be able to emit the "changed" signal
    def signal_do_on_menu(command)
    end
  end
  
end

if __FILE__ == $0
  
  class Tag
    include Singleton
    @@tags = []
    def self.find_or_create(new_name)
      @@tags << new_name unless @@tags.include? new_name
    end
    def self.rename(old_name, new_name)
      @@tags.delete old_name
      @@tags << new_name
    end
    def self.delete(old_name)
      @@tags.delete old_name
    end
  end

  # Demo
  APP = File.basename(__FILE__, '.*')

  ALPHABET = %w(Alpha Bravo Charlie Delta Echo Foxtrot Golf Hotel India Juliet Kilo Lima Mike November Oscar Papa Quebec Romeo Sierra Tango Uniform Victor Whiskey Xray Yankee Zulu)
  
  states = {}
  ALPHABET.each do |letter|
    states[letter] = false
  end
  
  states['Golf'] = true
  states['Papa'] = true
  
  Gtk.init
  
  window = Gtk::Window.new('TagsView Demo')
  window.set_default_size(500, 200)
  window.border_width=( 5 )
  window.signal_connect("destroy") { Gtk.main_quit }
  window.signal_connect("delete_event") { false }
  window.realize
  
  vbox = Gtk::VBox.new
  
  content = Gtk::Frame.new 'Content Area'
  
  tag_panel = TagsView.new(window, states, true, 6)
  tag_panel.signal_connect(TagsView::CHANGED) do |panel, states, command, old_tag, new_tag|
    puts "on_tags_changed(#{states.inspect}, :#{command}, '#{old_tag}', '#{new_tag}')\n\n"
  end
  
  vbox.pack_start(tag_panel, false, false, 5)
  vbox.pack_end(content, true, true, 5)
  
  window.add(vbox)
  window.show_all
  
  Gtk.main
end
