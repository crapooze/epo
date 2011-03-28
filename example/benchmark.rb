
$LOAD_PATH << './lib'
require './example/models'
require 'epo'
require 'json'
require 'yaml'

include EPO

db = DB.new([Person, Item])
root = './bench'

people = []
([['jon', 18], ['marc', 42], ['peter', 21]] * 1000).each_with_index.each do |ary, idx|
  args = ary + [idx]
  people << Person.new(*args)
end

items = []
3000.times do |t|
  item = Item.new('torch', 10)
  items << item 
  people[rand(3000)].items << item
end

#saving the objects
resources = [people, items].flatten


require 'benchmark'

Benchmark.benchmark do |x|
  x.report do
    db.batch_save(root, resources, [:default], ['.json'])
  end
  x.report do
    p db.each_resource_observation(root).to_a.size
  end
end
