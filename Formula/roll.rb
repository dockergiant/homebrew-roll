class DockerRequirement < Requirement
  fatal true

  DOCKER_MIN_VERS = "20.10.16"
  COMPOSE_MIN_VERS = "2.2.3"

  satisfy(build_env: false) { self.class.has_docker? }

  def message
    "Docker with Docker Compose >= #{COMPOSE_MIN_VERS} is " \
    "required for Den. Please install Docker Desktop via brew with 'brew " \
    "install --cask docker', download it from https://docker.com/ or use " \
    "your system package manager to install Docker Engine "\
    ">= #{DOCKER_MIN_VERS}"
  end

  def self.has_docker?
    self.docker_installed? &&
      (
        !self.docker_running? ||
        (
          self.docker_minimum_version_met? &&
          self.docker_compose_minimum_version_met?
        )
      )
  end

  def self.docker_running?
    docker_exec = self.get_docker_exec
    trash, status = Open3.capture2("#{docker_exec} system info")
    return status.success?
  end

  def self.docker_installed?
    return File.exists?("/Applications/Docker.app") &&
      File.exists?("/usr/local/bin/docker") if OS.mac?
    return File.exists?("/usr/bin/docker") if OS.linux?
  end

  def self.get_docker_exec
    return "/usr/local/bin/docker" if OS.mac?
    return "/usr/bin/docker" if OS.linux?
  end

  def self.docker_minimum_version_met?
    docker_exec = self.get_docker_exec
    current_vers, status =\
      Open3.capture2("#{docker_exec} version --format '{{.Server.Version}}'")
    return Gem::Version.new(current_vers) >= Gem::Version.new(DOCKER_MIN_VERS)
  end

  def self.docker_compose_minimum_version_met?
    docker_exec = self.get_docker_exec
    current_vers, status = Open3.capture2("#{docker_exec} compose version --short")
    return Gem::Version.new(current_vers) >= Gem::Version.new(COMPOSE_MIN_VERS)
  end
end

class Roll < Formula
  desc "RollDev is a CLI utility for working with docker-compose environments"
  homepage "https://getroll.dev"
  version "0.1.0-beta8"
  url "https://github.com/dockergiant/rolldev/archive/0.1.0-beta8.tar.gz"
  sha256 "7f096220e9c3b3b7a0de6791ad7eb6a8b0839e248c44b285ca16aecdc7385999"
  head "https://github.com/dockergiant/rolldev.git", :branch => "develop"

  depends_on DockerRequirement
  depends_on "gettext"
  depends_on "pv" => :recommended

  def install
    prefix.install Dir["*"]
  end

  def caveats
    <<~EOS
      RollDev manages a set of global services on the docker host machine. You
      will need to have Docker installed and docker-compose available in your
      local $PATH configuration prior to starting RollDev.

      To start roll simply run:
        roll svc up

      This command will automatically run "roll install" to setup a trusted
      local root certificate and sign an SSL certificate for use by services
      managed by roll via the "roll rolsign-certificate roll.test" command.

      To print a complete list of available commands simply run "roll" without
      any arguments.

      Documentation is available at: Not Yet Implemented
    EOS
  end
end
