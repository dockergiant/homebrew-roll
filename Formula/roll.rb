class DockerRequirement < Requirement
  fatal true

  DOCKER_MIN_VERS = "20.10.16"
  COMPOSE_MIN_VERS = "2.2.3"

  satisfy(build_env: false) { self.class.has_docker? }

  def message
    "Docker with Docker Compose >= #{COMPOSE_MIN_VERS} is " \
    "required for RollDev. Please install Docker Desktop via brew with 'brew " \
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
    return (File.exist?("/Applications/Docker.app") || File.exist?("/Applications/OrbStack.app")) &&
      File.exist?("/usr/local/bin/docker") if OS.mac?
    return File.exist?("/usr/bin/docker") if OS.linux?
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
  homepage "https://www.getroll.dev"
  version "0.3.2"
  url "https://github.com/dockergiant/rolldev/archive/0.3.2.tar.gz"
  sha256 "fd72691961992779960dd9fdd4fc87a4f2a4bc4a42d875c1b16765dde361c893"
  head "https://github.com/dockergiant/rolldev.git", :branch => "main"

  depends_on DockerRequirement
  depends_on "gettext" if OS.mac?
  depends_on "pv"
  depends_on "gum"
  depends_on "jq"
  depends_on "perl" if OS.mac?
  depends_on "pgrep" if OS.mac?
  depends_on "dialog"

  def install
    prefix.install Dir["*"]
  end

  def caveats
    <<~EOS
      RollDev manages a set of global services on the docker host machine. You
      will need to have Docker running and Docker Compose (>= 2.2.3) available in
      your local $PATH configuration prior to starting RollDev.

      To start roll simply run:
        roll svc up

      This command will automatically run "roll install" to setup a trusted
      local root certificate and sign an SSL certificate for use by services
      managed by roll via the "roll roll sign-certificate roll.test" command.

      To print a complete list of available commands simply run "roll" without
      any arguments.

      Documentation is available at: https://dockergiant.github.io/rolldev/
    EOS
  end
end
