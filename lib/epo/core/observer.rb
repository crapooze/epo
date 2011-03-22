
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
      full_dirname, base = File.split(path)
      dirname = if root
                  full_dirname.sub(root,'')
                else
                  full_dirname
                end
      #XXX may raise an exception for unknown path, we should rescue this/use a
      #silent method and test for nil
      db.get_route_silent(dirname)
    end

    # Read a single path, the root is the part of the path corresponding
    # to where on the filesystem the database is rooted.
    # e.g.  for a path in a photo collection:
    #       /home/crapooze/project/foobar/db/photo/1
    #       the root is likely to be:
    #       /home/crapooze/project/foobar/db
    # If a successful observation happens, then it will call the relevant hooks.
    def read_path(path, root=nil)
      node = get_node_for_path(path, root)
      return unless node
      # if there is no such route, it means we may prune the branch
      # if there is such a route but without content, it means we're on a directory of
      # a branch understood by the DB
      # XXX check for the root case

      persp_str = db.persp_and_ext_for_basename(path).first
      persp = node.content.perspectives.keys.find{|k| k.to_s == persp_str}
      observe_source(Source.new(db, path), structure(node.content, persp))
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
        if File.directory?(path)
          #XXX maybe prune the branch if valid but has no content
        elsif db.understands_ext?(path)
          read_path(path, root) 
        end
      end
    end
  end
end
