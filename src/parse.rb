#!/usr/bin/ruby

require File.dirname(__FILE__)+'/parser'

parser = Parser.new
article = parser.parse_text(ARGV[0])
puts article.get_parsed_text
