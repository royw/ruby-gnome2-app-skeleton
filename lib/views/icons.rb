##
# A class to encapsulate icons and images.
#
# Another layer class primarily to allow you to refer
# to images by abstract name instead of actual file name.
#
# === Usage
# home_image = Icons.image(:home)
# home_pixbuf = Icons.pixbuf(:home)
#
# This is a simple approach, IconThemes might be a more
# robust option especially if you need variable sizes of icons.
#
class Icons
  include Singleton

  ##
  # this is a hash of hashes.  Currently the inner hash is
  # just the filename, but the intent is to add license and
  # creator fields if that becomes necessary
  ICONS = {
      :email   => { :file => 'email-16.png' },
      :home    => { :file => 'home-16.png' }
    }

  attr_reader :icon_pixbuf

  ##
  # get the pixbuf for the named image
  #
  # @param [Symbol] name the abstract name of the image
  def self.pixbuf(name)
    instance.icon_pixbuf[name]
  end

  ##
  # get the Image for the named image
  #
  # @param [Symbol] name the abstract name of the image
  def self.image(name)
    img = Gtk::Image.new
    img.pixbuf = self.pixbuf(name)
    img
  end

  protected

  def initialize
    @logger = Log4r::Logger[APP]
    
    begin
      @icon_pixbuf = {}
      ICONS.keys.each do |key|
        @icon_pixbuf[key.to_s] = load_icon(key)
      end
    rescue RuntimeError => e
      @logger.error{"Couldn't load icon: #{e.message}"}
    end
  end

  def load_icon(key)
    pixbuf = nil
    @logger.info{"load_icon(#{key.to_s})"}
    icon_info = ICONS[key]
    if icon_info.nil?
      @logger.warn{"ICONS[#{key.to_s}] is nil"}
    else
      filename = icon_info[:file]
      if filename.nil?
        @logger.warn("ICONS[#{key.to_s}][:file] is nil")
      else
        filespec = File.join(ICON_DIR, filename)
        pixbuf = Gtk::Image.new(filespec).pixbuf
      end
    end
    pixbuf
  end
end
