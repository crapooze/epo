$LOAD_PATH << './lib'
require './example/models'
require 'epo'
require 'json'
require 'yaml'

include EPO

db = DB.new([Person, Item])
root = './db'

# enumerating on everything
db.each_resource(root) do |o|
  p o
end

# using explorers
obs = db.observer
obs.on(Person) do |o|
  p o.source.path
end
obs.read_tree(root) 

__END__
#using another, limited DB
#XXX will currently crash on Derailleur notfound
EPO::DB.new([Person]).each_resource(root) do |o|
  p o
end
