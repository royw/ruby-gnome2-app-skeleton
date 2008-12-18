#!/usr/bin/env ruby

require 'gtk2'

##
# A horizontal flow widget
#
# This is just a start, it needs some serious work especially
# with regards to handling child properties to make into a
# full blown container.
class HFlowBox < Gtk::EventBox
  attr_accessor :spacing
  
  # EventBox methods that we are replacing but still want to
  # be able to call.
  # alias new_name old_name
  alias eventbox_add add
  
  def initialize(window)
    super()
    
    @spacing = 0
    
    buffer = Gtk::TextBuffer.new
    buffer.text = ''
    @textview = Gtk::TextView.new buffer
    @textview.wrap_mode = Gtk::TextTag::WRAP_WORD
    @textview.editable = false
    @textview.cursor_visible = false
    
    eventbox_add @textview   # add to EventBox
  
    # set the background color of the TextView to be the window's
    # background color
    window.realize
    org_bg = window.style.bg(Gtk::STATE_NORMAL)
    @textview.modify_base(Gtk::STATE_NORMAL, org_bg)
  end
  
  def set_spacing(pixels)
    @spacing = pixels
  end

  def spacing=(pixels)
    set_spacing(pixels)
  end
  
  def tooltip_text=(str)
    @textview.tooltip_text = str
  end
  
  # Adds widget to container. Typically used for simple containers such as 
  # Gtk::Window, Gtk::Frame, or Gtk::Button; for more complicated layout 
  # containers such as Gtk::Box or Gtk::Table, this method will pick default 
  # packing parameters that may not be correct. So consider methods such as 
  # Gtk::Box#pack_start and Gtk::Table#attach as an alternative to 
  # Gtk::Container#add in those cases. A widget may be added to only one 
  # container at a time; you can't place the same widget inside two different 
  #containers.
  #
  #  * widget: a Gtk::Widget to be placed inside container
  #  * child_properties: a hash of child properties({type => value, type2 => value, ...})
  #  * Returns: self
  # TODO: what to do with child_properties?
  def add(widget, child_properties=nil)
    iter = @textview.buffer.end_iter
    anchor = @textview.buffer.create_child_anchor(iter)
    @textview.add_child_at_anchor(widget, anchor)
#     unless child_properties.nil?
#       child_properties.each { |k,v| widget.set_property(k,v) }
#     end
#     widget.set_property('position', @textview.buffer.char_count)
    self
  end
  
  # Same as Gtk::Container#add
  # 
  #  * widget: a Gtk::Widget to be placed inside container
  #  * Returns: self
  def <<(widget)
    add(widget)
    self
  end
  
  # Removes widget from container. widget must be inside container.
  # 
  #   * widget : a current child Gtk::Widget of the container
  #   * Returns: self
  def remove(widget)
    iter = get_iter_at_child(widget)
    remove_anchor_at_iter(iter)
    recalculate_position_properties()
    self
  end
  
  def children
    widgets = []
    iter = @textview.buffer.start_iter
    begin
      widgets << iter.child_anchor.widgets[0]
      iter.forward_char
    end while !iter.end?
    widgets
  end
  
  def focus_child=(widget)
    set_focus_child(widget)
  end
  
  def set_focus_child(widget)
    widget.grab_focus
  end
  
  def each(&block)
    children.each {|child| block.call(child)}
  end
  
  # Moves child to a new position in the list of box children. 
  # 
  #  * widget: the child Gtk::Widget to move.
  #  * position: the new position for child in the children list of Gtk::Box, 
  #    starting from 0. If negative, indicates the end of the list.
  #  * Returns: self
  def reorder_child(widget, position)
    src_iter = get_iter_at_child(widget)
    unless src_iter.nil?
      offset = 0
      if position >= 0
        offset = position
      else
        offset = @textview.buffer.char_count + position
      end
      dest_iter = @textview.buffer.get_iter_at_offset(offset)
      
      # insert widget at new position
      anchor = @textview.buffer.create_child_anchor(dest_iter)
      @textview.add_child_at_anchor(widget, anchor)
      
      # remove widget from old position
      remove_anchor_at_iter(src_iter)
    
      recalculate_position_properties()
    end
  end
  
  protected
  
  def get_iter_at_child(widget)
    child_iter = nil
    iter = @textview.buffer.start_iter
    begin
      if iter.child_anchor.widgets.include? widget
        child_iter = iter
        break
      end
      iter.forward_char
    end while !iter.end?
    child_iter
  end

  def remove_anchor_at_iter(iter)
    unless iter.nil?
      end_iter = iter.copy
      end_iter.forward_chars(1)
      unless end_iter.nil?
        @textview.buffer.delete(iter, end_iter)
      end
    end
  end

  def recalculate_position_properties()
#     i = 0
#     children.each { |widget| widget.set_property('position', i); i += 1 }
  end
  
end

if __FILE__ == $0

  # Demo
  
  ALPHABET = %w(Alpha Bravo Charlie Delta Echo Foxtrot Golf Hotel India Juliet Kilo Lima Mike November Oscar Papa Quebec Romeo Sierra Tango Uniform Victor Whiskey Xray Yankee Zulu)
  
  Gtk.init
  
  window = Gtk::Window.new('HFlowBox Demo')
  window.set_default_size(500, 200)
  window.border_width=( 5 )
  window.signal_connect("destroy") { Gtk.main_quit }
  window.signal_connect("delete_event") { false }
  window.realize
  
  vbox = Gtk::VBox.new
  
  content = Gtk::Frame.new 'Content Area'
  
  fbox = HFlowBox.new(window)
  ALPHABET.each do |letter|
    puts "letter => #{letter}"
    btn = Gtk::Button.new letter
    btn.signal_connect('clicked') {|btn| puts "#{btn.get_property('position')} #{btn.label}"; fbox.remove(btn)}
    fbox.add(btn)
  end
  
  vbox.pack_start(fbox, false, false, 5)
  vbox.pack_end(content, true, true, 5)
  
  window.add(vbox)
  window.show_all
  
  Gtk.main
end
