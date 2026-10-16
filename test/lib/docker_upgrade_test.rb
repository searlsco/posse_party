require "test_helper"
require "open3"
require "tmpdir"

class DockerUpgradeTest < ActiveSupport::TestCase
  setup do
    @directory = Dir.mktmpdir
    File.write(File.join(@directory, "docker-compose.yml"), "")
    File.write(File.join(@directory, ".env"), "POSSE_IMAGE=ghcr.io/example/app:latest\n")
    File.write(File.join(@directory, "docker"), <<~BASH)
      #!/usr/bin/env bash
      set -euo pipefail
      echo "$*" >> "$DOCKER_TRACE"
      case "$*" in
        'compose -f docker-compose.yml ps -q web') echo web-container ;;
        'inspect --format {{.Image}} web-container') echo current-image ;;
        'image inspect --format {{index .RepoDigests 0}} current-image') echo example/app@sha256:current ;;
        'image prune --force')
          test "${PRUNE_FAIL:-0}" = 0
          touch reclaimed
          ;;
        'compose -f docker-compose.yml pull')
          test -f reclaimed || { echo 'no space left on device' >&2; exit 1; }
          ;;
      esac
    BASH
    File.chmod(0o755, File.join(@directory, "docker"))
    @environment = {
      "PATH" => "#{@directory}:#{ENV.fetch("PATH")}",
      "DOCKER_TRACE" => File.join(@directory, "trace"),
      "POSSE_IMAGE" => nil
    }
  end

  teardown do
    FileUtils.remove_entry(@directory)
  end

  def test_reclaims_dangling_images_before_pulling_and_restarting
    output, status = Open3.capture2e(@environment, "bash", Rails.root.join("script/docker_upgrade").to_s, chdir: @directory)

    assert status.success?, output
    commands = File.readlines(@environment.fetch("DOCKER_TRACE"), chomp: true)
    assert_includes commands, "image prune --force"
    assert_includes commands, "compose -f docker-compose.yml up -d"
    assert_includes output, "No upgrade found"
  end

  def test_cleanup_failure_stops_before_pulling_or_restarting
    _, status = Open3.capture2e(@environment.merge("PRUNE_FAIL" => "1"), "bash", Rails.root.join("script/docker_upgrade").to_s, chdir: @directory)

    refute status.success?
    commands = File.readlines(@environment.fetch("DOCKER_TRACE"), chomp: true)
    assert_includes commands, "image prune --force"
    refute_includes commands, "compose -f docker-compose.yml pull"
    refute_includes commands, "compose -f docker-compose.yml up -d"
  end
end
