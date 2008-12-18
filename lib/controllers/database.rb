require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-types'
require 'dm-aggregates'
require 'dm-serializer'

##
# Setup and connect to the database.
# Also load a new database with any initial data
class Database
  include Singleton

  ##
  # load initial data into the database
  def setup
    ##
    # connect to database using Datamapper
    DataMapper.setup(:default, {
                                :adapter => 'sqlite3',
                                :database => "#{DB_NAME}"
                              })

    DataObjects::Sqlite3.logger = DataMapper::Logger.new("#{APP}-db.log", :debug) if ENV['DB_LOG'] == 'ON'

    # TODO: auto upgrading is fine for development but should be
    # removed for production
    DataMapper.auto_upgrade!

    initial_data_load
  end

  protected

  def initial_data_load
    # TODO: Add any intial data loads the application needs
  end

end
