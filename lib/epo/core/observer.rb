
require 'welo'
require 'find'
require 'epo/core/db'
require 'epo/core/dispatch_observations'

module EPO
  # An Observer is a object able to look at the filesystem and 
  # observe resources in it.
  class Observer < Welo::Observer
    include DispatchObservations
    # in EPO, the source of an observation is:
    # - a db object able to make a ruby object from a file path
    # - a file path
    Source = Struct.new(:db, :path) do
      def observe
        db.read_file(path)
      end
    end

    # The DB able to tell if a path is understandable or not
    attr_accessor :db

    # A cache for the observation structures
    attr_accessor :structures

    # Creates and return a new observer from a DB. 
    # It will take the models from the DB.
    def self.for_db(db)
      obj = self.new(db.models)
      obj.db = db
      obj
    end

    # Creates a new observer for given models.
    # Will instanciate a new DB.
    def initialize(models=[])
      super(models)
      @db = DB.new(models)
      @structures = {}
      register(:observation) do |o|
        dispatch(o)
      end
    end

    def get_node_for_path(path, root=nil)
      path = path.sub(root,'') if root
      db.get_route_silent(path)
    end

    def read_path_as_resource(path, model)
      persp_str = db.persp_and_ext_for_basename(path).first
      persp = model.perspectives.keys.find{|k| k.to_s == persp_str}
      observe_source(Source.new(db, path), structure(model, persp))
    end

    def structure(model, persp)
      pair = [model, persp]
      @structures[pair] ||= Welo::ObservationStruct.new_for_resource_in_perspective(model, persp)
    end

    # Recursively reads the files in the filesystem (with Find).
    # For each path, will try to read_path
    # Currently, there is no pruning, or control possible.
    def read_tree(root)
      Find.find(root) do |path|
        node = get_node_for_path(path, root) 
        if node 
          if node.content #a model attached to a file in a directory
            read_path_as_resource(path, node.content)
          end
        else #the db doesn't understand this branch, we'd rather drop now
          Find.prune
        end
      end
    end
  end
end
