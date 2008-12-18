##
# add a mkdirs method to the File class
class File
  ##
  # make directories including any missing in the path
  #
  # @param [String] dirspec the path to make sure exists
  def File.mkdirs(dirspec)
    unless File.exists?(dirspec)
      mkdirs(File.dirname(dirspec))
      Dir.mkdir(dirspec)
    end
  end
end

##
# add a blank? method to String
class String
  def blank?
    nil? || strip.empty?
  end
end
