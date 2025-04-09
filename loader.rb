# frozen_string_literal: true

require "rufus-scheduler"
require "pathname"
require "dry-auto_inject"

require_relative "job"

class ScriptLoader
    include Services[:logger]
    include Services[:scheduler]
    include Services[:scripts_path]
    include Services[:paint]

    def load_scripts!
        logger.info("loading scripts")
        num_scripts = 0
        Pathname(scripts_path).glob("*.rb").each do |file|
            self.load_script(file)
            num_scripts += 1
        end
        logger.info("loaded #{paint.green(num_scripts)} script#{num_scripts == 1 ? "" : "s"}")
    end

    def load_script(file, reload: false)
        @jobs ||= {}
        logger.info("loading script #{file}")

        begin
            if reload
                load(file)
            else
                require(file)
            end

            num_jobs = 0
            ObjectSpace.each_object(Class) do |klass|
                next unless klass < Job

                if @jobs.key?(klass.id) && !reload
                    raise ArgumentError, "#{paint.cyan(klass.name)}.id in #{file} is not unique!"
                end

                if @jobs.key?(klass.id)
                    logger.info("unloading job #{paint.cyan(klass.name)} from #{file}")
                    @jobs[klass.id].unschedule
                    @jobs.delete(klass.id)
                end

                job = klass.new
                job.schedule => [how, expr, *args]
                kwargs = args.reduce({:name => klass.id}) { |acc, x| acc.merge(x) }
                @jobs[klass.id] = @scheduler.send("schedule_#{how}", expr, proc { job.execute }, **kwargs )
                @logger.info("#{reload ? "re" : ""}loaded job #{paint.cyan(@jobs[klass.id].name)} from #{file}")
                num_jobs += 1
            end
            logger.info("loaded #{paint.green(num_jobs)} job#{num_jobs == 1 ? "" : "s"} from #{file}")
        rescue Exception => e
            logger.error("error loading script #{file}: #{e.message}")
        end
    end
end
