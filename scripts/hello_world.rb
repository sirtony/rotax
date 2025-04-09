# frozen_string_literal: true

# all jobs should inherit from Job
class HelloWorld < Job
    # Dry::AutoInject is used for IoC
    # services are loaded via the Service constant
    include Services[:logger]

    def self.id
        # this can be anything, as long as it's unique among all scripts
        # using a const UUIDv4 is just for convenience
        "254f5ec4-4895-4f40-b3a5-c5ba0451fa2c"
    end

    def schedule
        # equivalent to calling scheduler.cron("@hourly", first_in: "3s", name: "hello_world") { ... }
        # the first argument can be anything that rufus scheduler supports, :every, :repeat, ...
        # the second argument is the scheduler. supports any string that rufus-scheduler supports
        # the remainder of the array may be an array of hashed containing kwargs passed to rufus
        # this will schedule a job using a cron expression to run every hour, and once 3 seconds after being scheduled
        [:cron, "@hourly", { :first_in => "3s", :name => "hello_world" }]
    end

    # the business logic for the job
    def execute
        logger.info("Hello, World!")
    end
end
