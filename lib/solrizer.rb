require 'rubygems'
module Solrizer
  class Extractor
  end
end

Dir[File.join(File.dirname(__FILE__),"solrizer","*.rb")].each {|file| require file }
