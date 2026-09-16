class DockerRequirement < Requirement
  fatal true

  DOCKER_MIN_VERS = "20.10.16"
  COMPOSE_MIN_VERS = "2.2.3"

  satisfy(build_env: false) { self.class.has_docker?(which("docker")) }

  def message
    "Docker with Docker Compose >= #{COMPOSE_MIN_VERS} is " \
    "required for RollDev. Please install Docker Desktop via brew with 'brew " \
    "install --cask docker', download it from https://docker.com/, install " \
    "OrbStack or Colima, or use your system package manager to install Docker Engine "\
    ">= #{DOCKER_MIN_VERS}"
  end

  def self.has_docker?(docker_exec)
    return false if docker_exec.nil?

    !self.docker_running?(docker_exec) ||
      (
        self.docker_minimum_version_met?(docker_exec) &&
        self.docker_compose_minimum_version_met?(docker_exec)
      )
  end

  def self.docker_running?(docker_exec)
    _output, status = Open3.capture2e(docker_exec.to_s, "system", "info")
    return status.success?
  end

  # Distribution packages append a suffix Gem::Version rejects, e.g. Ubuntu's 2.40.3+ds1-0ubuntu1~24.04.1
  def self.parse_version(output)
    return Gem::Version.new(output[/\d+(?:\.\d+)+/] || "0")
  end

  def self.docker_minimum_version_met?(docker_exec)
    current_vers, _status = Open3.capture2(docker_exec.to_s, "version", "--format", "{{.Server.Version}}")
    return self.parse_version(current_vers) >= Gem::Version.new(DOCKER_MIN_VERS)
  end

  def self.docker_compose_minimum_version_met?(docker_exec)
    current_vers, _status = Open3.capture2(docker_exec.to_s, "compose", "version", "--short")
    return self.parse_version(current_vers) >= Gem::Version.new(COMPOSE_MIN_VERS)
  end
end

class Roll < Formula
  desc "RollDev is a CLI utility for working with docker-compose environments"
  homepage "https://dockergiant.github.io/rolldev/"
  version "0.7.0"
  url "https://github.com/dockergiant/rolldev/archive/0.7.0.tar.gz"
  sha256 "5df1f7e14586475f698a2b78ac7f3f36f06850a6043fa55dd2223c869231c3ba"
  head "https://github.com/dockergiant/rolldev.git", :branch => "main"

  depends_on DockerRequirement
  depends_on "gettext" if OS.mac?
  depends_on "jq"

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
      managed by roll via the "roll sign-certificate roll.test" command.

      To print a complete list of available commands simply run "roll" without
      any arguments.

      Encrypted backups (roll backup --encrypt) need GnuPG:
        brew install gnupg

      Documentation is available at: https://dockergiant.github.io/rolldev/
    EOS
  end
end
