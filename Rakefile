require 'rake'
require 'redcloth'

namespace :doc do
  desc 'convert textile files to html'
  task :textile do
    Dir.glob('*.textile').each do |filename|
      puts filename
      r = RedCloth.new IO.read(filename)
      File.open("doc/#{File.basename(filename, '.*')}.html", "w") do |file|
	file.puts r.to_html
      end
    end
  end
end
