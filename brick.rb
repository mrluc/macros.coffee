require 'webrick'
include WEBrick
S = HTTPServer.new(:Port => 2000, :DocumentRoot => Dir.pwd )
p Dir.pwd
trap("INT"){ s.shutdown }
S.start

