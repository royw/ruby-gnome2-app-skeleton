class PromptDialog < Gtk::Dialog
  def initialize(title, window, instructions, default_value)
    super(title, window,
          Gtk::Dialog::MODAL | Gtk::Dialog::DESTROY_WITH_PARENT,
          [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT],
          [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_REJECT])

    @logger = Log4r::Logger[APP]
    @logger.debug{"PromptDialog.new(#{title}, window, #{instructions}, #{default_value.inspect})"}

    self.window_position = Gtk::Window::POS_CENTER_ON_PARENT
    self.border_width = 5
    self.default_response = Gtk::Dialog::RESPONSE_ACCEPT

    label = Gtk::Label.new(instructions)
    self.vbox.pack_start(label, false, false, 2)
    unless default_value.nil?
      if default_value.kind_of? Array
        @combobox = Gtk::ComboBox.new(true)  # text only combo
        default_value.each { |str| @combobox.append_text(str.to_s) }
        self.vbox.pack_start(@combobox, false, false, 2)
      else
        @entry = Gtk::Entry.new
        @entry.activates_default = true
        @entry.text = default_value.to_s
        self.vbox.pack_start(@entry, false, false, 2)
      end
    end
  end

  def value
    v = nil
    unless @entry.nil?
      v = @entry.text
    end
    unless @combobox.nil?
      v = @combobox.active_text
    end
    v
  end

end