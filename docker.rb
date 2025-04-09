#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "version"

REPOSITORY = "ghcr.io/sirtony/rotax"

if system("docker build -t #{REPOSITORY}:#{VERSION} .")
    system("docker tag #{REPOSITORY}:#{VERSION} #{REPOSITORY}:latest")

    if ARGV.include?("--push")
        system("docker push #{REPOSITORY}")
    end
end
