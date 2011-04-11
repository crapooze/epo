
require 'welo'
require 'find'
require 'epo/core/db'

module EPO
  # An Observer is a object able to look at the filesystem and 
  # observe resources in it.
  class Observer < Welo::Observer
    alias :on :register

    # in EPO, the source of an observation is:
    # - a db object able to make a ruby object from a file path
    # - a file path
    Source = Struct.new(:db, :path) do
      def observe
        yield db.read_file(path)
      end
    end

    # The list of models understood by this observer
    attr_reader :models

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
      super()
      @db = DB.new(models)
      @structures = {}
      register(:observation) do |o|
        event(o.class.resource, o)
      end
    end

    # Returns the node for a db path, or nil if doesnt exist
    def get_node_for_path(path, root=nil)
      case root
      when Regexp
        path = path.sub(root,'') 
      when String
        re = %r{^#{root}}
        path = path.sub(re,'') 
      when nil
        #ok
      else
        raise ArgumentError, "can only understand string or regexps as roots" 
      end
      db.get_route_silent(path)
    end

    # Reads the file to path as a resource dumped EPO-style
    def read_path_as_resource(path, model)
      persp_str = db.persp_and_ext_for_basename(path).first
      persp = model.perspectives.keys.find{|k| k.to_s == persp_str}
      observe_source(Source.new(db, path), structure(model, persp))
    end

    # Handy-cache for mapping (model, persp) pairs to Welo::ObservationStruct
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
            if db.understands_filename?(path)
              read_path_as_resource(path, node.content)
            end
          end
        else #the db doesn't understand this branch, we'd rather drop now
          Find.prune
        end
      end
    end
  end
end
