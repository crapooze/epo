$LOAD_PATH << './lib'
require './example/models'
require 'epo'
require 'json'

include EPO

db = DB.new([Person, Item])
root = './db'

jon = Person.new('jon', 18)
path = File.join(root, jon.path(db.identifying_sym), "foobar")

#creates the dir + the file
db.save(root, jon)
FileUtils.touch(path, :verbose => true)


#delete, omitting non-epo files
db.delete(root, jon)
p File.file?(path)

#save again
db.save(root, jon)

#delete everything
db.delete_completely(root, jon)
p File.file?(path)
