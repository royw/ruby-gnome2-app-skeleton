##
# Store configuration key/value pairs in a database table
#
# Not very generic as the key is limited to 80 character String
# and the value is limited to 255 character String.
class Configuration
  include DataMapper::Resource
  include DataMapper::Timestamp
  include DataMapper::Serialize
  property :id,               Serial
  property :name,             String, :nullable => false, :length => 80
  property :value,            String, :length => 255
  property :created_at, DateTime
  property :updated_at, DateTime

  # this is a good place to put configuration name constants.
  APP_SIZE_WIDTH = 'app_size_width'
  APP_SIZE_HEIGHT = 'app_size_height'
  APP_POSITION_X = 'app_position_x'
  APP_POSITION_Y = 'app_position_y'

  @@logger = Log4r::Logger[APP]

  ##
  # find or create the record specified by the given name
  # and assign the given default_value if the record is created.
  #
  # @param [String] name the record name
  # @param [String] default_value the value to assign upon creation
  def self.find_or_create(name, default_value)
    config = Configuration.first(:name => name)
    if config.nil?
      config = Configuration.create(:name => name, :value => default_value)
      config.do_save("find_or_create(#{name}, #{default_value}) creating Configuration item")
    end
    config
  end

  def self.set(name, value)
    config = Configuration.find_or_create(name, value)
    config.value = value
    config.do_save("set(#{name}, #{value})")
  end

  def self.get(name, default_value=nil)
    config = Configuration.find_or_create(name, default_value)
    config.value
  end
  
  def asserted?
    %w(on true 1).include? value 
  end

  ##
  # a save with error logging method
  #
  # @param [String] msg msg is an optional message to log
  #
  def do_save(msg=nil)
    unless self.save || self.errors.empty?
      @@logger.error{msg} unless msg.nil?
      @@logger.error{self.inspect}
      @@logger.error{self.errors.collect{|e| '  ' + e.inspect}.join("\n")}
    end
  end

end