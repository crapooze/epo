
require 'derailleur/core/application'
require 'fileutils'

module EPO
  class DB
    include Derailleur::Application

    # The list of understood models, models must behave like Welo::Resources
    attr_reader :models

    # A list of understood extensions (e.g., '.json', '.yaml'), default is '.json'
    attr_reader :extensions

    # The name of the identifiers to use to map Welo::Resources to directories
    attr_reader :identifying_sym

    # Creates a new DB
    # models: the list of Welo::Resource models to use (i.e., classes)
    def initialize(models, params={})
      @models = models
      @extensions = params[:extensions] || ['.json']
      @identifying_sym = params[:identifying_sym] || :flat_db
      build!
    end

    private

    # creates the tree to map the DB structure to classes paths
    # does not register the model because it uses existing one
    def build!
      models.each do |model|
        build_route_for_model(model)
      end
    end

    public

    # Registers a model on a derailleur node at its path_model
    # Does not modify self.models
    def build_route_for_model(model)
      path = File.join(model.path_model(identifying_sym), ':filename')
      node = build_route(path)
      node.content = model
    end

    # Updates self.models and build a route for the model
    # raise an error if the model is already known
    def register_model(model)
      raise ArgumentError, "already know this model" if models.include?(model)
      models << model
      build_route_for_model(model)
    end

    # Loads the file at path and turn it to a ruby object based on the file extension.
    # If the file extension is not supported, will raise an error.
    # uses JSON.parse(File.read(path)) and YAML.load_file(path) for '.json' and '.yaml'
    # otherwise, will forward the handling such that 
    # '.foobaar' maps to :read_foobar(path)
    def read_file(path)
      raise ArgumentError, "don't know extension #{ext}, use from [#{extensions.join(', ')}]" unless understands_ext?(path)
      ext = File.extname(path)
      case ext
      when '.json'
        JSON.parse(File.read(path))
      when '.yaml'
        YAML.load_file(path)
      else
        self.send "read_#{ext.tr('.','')}", path
      end
    end

    # Wether or not this DB understands the extension of the file at path.
    def understands_ext?(path)
      extensions.find{|ext| ext == File.extname(path)}
    end

    # Returns the perspective name and extension name (a 2 items array)
    # for the given path.
    # By default the blobs for resources content are stored in files named
    # 'resource-<persp><ext>' with ext starting with a dot
    def persp_and_ext_for_basename(path)
      base = File.basename(path).sub('resource-','').sub(/\.[^\.]+$/,'')
      [base, File.extname(path)]
    end

    # Returns the basename of a resource blob for a perspective named persp and
    # in a format with extension ext (including the leading dot).  
    # see also persp_and_ext_for_basename
    def basename_for_persp_and_ext(persp, ext)
      "resource-#{persp}#{ext}"
    end

    # Saves one or more resource at the filesystem path given at root
    # This method is mainly an handy helper around batch_save, look at the
    # source and at batch_save's doc
    def save(root, resource, perspective=:default, exts=nil)
      exts ||= extensions
      batch_save(root, [resource].flatten, [perspective].flatten, [exts].flatten)
    end

    # Saves all the resources, under all the perspectives persps, and all format
    # given by extensions exts at the filesystem path root.
    # resources, perps, exts, must respond to :each, like for Enumerable
    def batch_save(root, resources, persps, exts)
      batch_save_actions(root, resources, persps, exts) do |action|
        action.perform
      end
    end

    # Yields all the action needed to store all the resources
    # at perspectives persps and with formats exts.
    # All actions respond to :perform (it is when they're executed).
    # If no block given, returns an Enumerator with these actions.
    def batch_save_actions(root, resources, persps, exts)
      if block_given?
        resources.each do |resource|
          db_path = File.join(root, resource.path(identifying_sym))
          yield PrepareDirAction.new(db_path)
          exts.each do |ext|
            persps.each do |persp|
              basename = basename_for_persp_and_ext(persp, ext)
              resource_path = File.join(db_path, basename) 
              yield StoreResourceAction.new(resource_path, resource, persp, ext)
            end
          end
        end
      else
        Enumerator.new(self, root, resources, persps, exts)
      end
    end

    # An action to prepare the directory for a resource
    PrepareDirAction = Struct.new(:path) do
      def perform
        FileUtils.mkdir_p(path)
      end
    end

    # An action to serialize and store a resource seen in a given perspective
    # into a file at path, under the format with a format given by its
    # extension name.
    StoreResourceAction = Struct.new(:path, :resource, :persp, :ext) do
      def perform
        data = resource.to_ext(ext.to_s, persp)
        store_data_at_path(data, path)
      end

      def store_data_at_path(data, path, enum=:each, mode='w')
        File.open(path, mode) do |f|
          write_data_to_io(data, f, enum)
        end
      end

      def write_data_to_io(data, io, enum=:each)
        if data.respond_to?(enum)
          data.each do |buf|
            io << buf
          end
        else
          io << data
        end
      end
    end

    # Returns a new EPO::Observer for itself
    def observer
      Observer.for_db(self)
    end

    # Iterates on every resource found and understood in the filesystem
    # directory root.
    # If no block is given, returns an iterator.
    def each_resource(root) 
      if block_given?
        xp = observer
        models.each do |model|
          xp.on(model) do |obs|
            yield obs
          end
        end
        xp.read_tree(root)
      else
        Enumerator.new(self, :each_resource, root)
      end
    end

  end
end
