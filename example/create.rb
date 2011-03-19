$LOAD_PATH << './lib'
require './example/models'
require 'epo'
require 'json'
require 'yaml'

include EPO

db = DB.new([Person, Item])
root = './db'

#crafting some objects
people = [['jon', 18], ['marc', 42], ['peter', 21]].each_with_index.map do |ary, idx|
  args = ary + [idx]
  Person.new(*args)
end
items = []
items << Item.new('torch', 10)
people.first.items << items.first

#saving the objects
resources = [people, items].flatten
db.batch_save(root, resources, [:default, :all], ['.json'])
