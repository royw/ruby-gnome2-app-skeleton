##
# A class to encapsulate running external applications.
#
# This is pretty primitive, but experience shows it's good
# to have this layer instead of calling external apps everywhere.
class ExternalApplication

  @@logger = Log4r::Logger[APP]
  
  def self.run(cmd_line)
    `#{cmd_line}`
  end

  # launch the given URL in default web browser
  def self.web_browse(url)
    unless url.nil?
      url = 'http://' + url unless url =~ /^http/i
      @@logger.info{"launch \"#{url}\""}
      Launchy.open(url)
    end
  end

end