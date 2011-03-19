
module EPO
  module DispatchObservations
    # Register an event when an observation of a resource
    # matching a given model is made
    def on(model,&blk)
      register(model,&blk)
    end

    private

    # Call each blocks for an observation registering from the 
    # observation's resource model
    def dispatch(observation)
      blks = registrations[observation.class.resource] || []
      blks.each do |blk|
        blk.call(observation)
      end
    end
  end
end
