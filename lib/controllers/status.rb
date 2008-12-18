##
# Class to manage the app's status bar
#
# Wraps a context in an instance.
class Status
  @@statusbar = Gtk::Statusbar.new
  @@statusbar.has_resize_grip = false

  ##
  # class accessor for the statusbar
  def self.statusbar
    @@statusbar
  end

  ##
  # display a message in the status bar, call the code block,
  # then pop the message off of the status bar.
  #
  # @param [#to_s] msg the message to display in the status bar
  # @param [Boolean] nice if asserted then let Gtk do some loop
  # processing after the status message is shown but before the
  # block is called.
  # @yield [] the block of code to execute while the status message
  # is displayed
  def self.status(msg, nice=false, &block)
    stat = Status.new(msg.to_s)
    stat.push(msg)
    App.be_nice if nice
    block.call
    stat.pop
  end

  ##
  # new
  #
  # @param [String] context_string the context for the status messages.
  # Suggest is the class name that this instance is in.
  def initialize(context_string)
    @context_id = @@statusbar.get_context_id(context_string)
    @message_ids = []
  end

  ##
  # push a message onto the status bar
  #
  # @param [#to_s] msg the message to display on the status bar
  def push(msg)
    @message_ids << @@statusbar.push(@context_id, msg.to_s)
  end

  ##
  # remove the latest message within this context from the status bar
  def pop
    @@statusbar.pop(@context_id)
  end

  ##
  # replace the latest message within this context with the given
  # message on the status bar
  #
  # @param [#to_s] msg the message to display on the status bar
  def replace(msg)
    remove_all
    push(msg)
  end

  ##
  # remove all messages within this context from the status bar.
  def remove_all
    @message_ids.each do |msg_id|
      @@statusbar.remove(@context_id, msg_id)
    end
    @message_ids.clear
  end

end
