
require 'welo'

class Item
  include Welo::Resource
  perspective :default, [:name, :price]
  identify :default, [:uuid]
  identify :flat_db, [:uuid]
  attr_reader :name, :price, :uuid
  def initialize(name, price=0, uuid=nil)
    @name = name
    @price = price
    @uuid = uuid || rand(65535)
  end
end

class Person
  include Welo::Resource
  perspective :default, [:name, :age, :items]
  perspective :all, [:name, :age, :run_id]
  identify :flat_db, [:name, :run_id]
  relationship :items, :Item, [:many]
  attr_reader :name, :age, :run_id, :items
  def initialize(name, age, id=0)
    @name = name
    @age = age
    @run_id = id
    @items = []
  end
end
