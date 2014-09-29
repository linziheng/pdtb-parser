#!/usr/bin/ruby

require File.dirname(__FILE__)+'/trainer'

trainer = Trainer.new
puts "Training started..."
trainer.train
puts "Done training."
