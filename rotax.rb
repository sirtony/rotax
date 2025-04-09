# frozen_string_literal: true

require "pastel"
require "tty-logger"
require "rufus-scheduler"
require "dry-container"
require "dry-auto_inject"
require "bundler"
require "pathname"
require "listen"
require "fileutils"

IS_DOCKER = ENV["container"] != nil || File.exist?("/.dockerenv")
SEARCH_PATH = IS_DOCKER ? "/scripts" : "./scripts"

scheduler = Rufus::Scheduler.new
paint = Pastel.new(enabled: $stdout.tty?)
logger = TTY::Logger.new do |config|
    config.metadata = [:date, :time]
end
container = Dry::Container.new
container.register(:logger, logger)
container.register(:scheduler, scheduler)
container.register(:paint, paint)
container.register(:scripts_path, SEARCH_PATH)
container.register(:container, container)

Services = Dry::AutoInject(container)

require_relative "job"
require_relative "loader"

GEMFILE = Pathname("#{SEARCH_PATH}/Gemfile")

unless Dir.exist?(SEARCH_PATH)
    FileUtils.mkdir_p(SEARCH_PATH)
end

logger.info("#{paint.cyan(File.basename(__FILE__, ".*"))} is starting")
logger.info("environment: #{IS_DOCKER ? "Docker" : "host system"}")
logger.info("checking for dependencies")

if File.exist?(GEMFILE) && File.file?(GEMFILE)
    definition = Bundler::Definition.build(GEMFILE, nil, false)
    definition.resolve_with_cache!

    Bundler::Installer.install(Bundler.root, definition)
else
    logger.info("no dependencies found, skipping")
end

loader = ScriptLoader.new
loader.load_scripts!

listener = Listen.to(SEARCH_PATH) do |modified, added, removed|
    added.each { |path| loader.load_script(path) }
    modified.each { |path| loader.load_script(path, reload: true) }
    removed.each do |path|
        logger.warn("#{path} was deleted but the script cannot be unloaded; a restart is required to disable it")
    end
end

begin
    listener.start
    scheduler.join
rescue Interrupt
    puts
    logger.info("shutting down gracefully")
    listener.stop
    scheduler.shutdown
    scheduler.join
rescue Exception => e
    logger.error("error running scheduler: #{e.message}")
ensure
    logger.info("goodbye!")
end
