#!/usr/bin/env ruby

require "json"
require "rubygems"
require "spaceship"

bundle_id = ARGV.first
abort "Usage: bundle exec ruby asc_release_state.rb <bundle-id>" if bundle_id.to_s.empty?

key_path = ENV["ASC_KEY_FILEPATH"] || ENV["ASC_KEY_PATH"]
required = {
  "ASC_KEY_ID" => ENV["ASC_KEY_ID"],
  "ASC_ISSUER_ID" => ENV["ASC_ISSUER_ID"],
  "ASC_KEY_FILEPATH or ASC_KEY_PATH" => key_path,
}
missing = required.select { |_name, value| value.to_s.empty? }.keys
abort "Missing environment variables: #{missing.join(', ')}" unless missing.empty?

Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(
  key_id: ENV.fetch("ASC_KEY_ID"),
  issuer_id: ENV.fetch("ASC_ISSUER_ID"),
  filepath: key_path,
)

app = Spaceship::ConnectAPI::App.find(bundle_id)
abort "App not found for bundle ID: #{bundle_id}" unless app

versions = app.get_app_store_versions(filter: { platform: "IOS" })
released_states = %w[READY_FOR_DISTRIBUTION READY_FOR_SALE].freeze
released_versions = versions.select { |version| released_states.include?(version.app_version_state) }
latest_released = released_versions.max_by { |version| Gem::Version.new(version.version_string) }

builds = app.get_builds(
  includes: Spaceship::ConnectAPI::Build::ESSENTIAL_INCLUDES,
  limit: 200,
  sort: "-uploadedDate",
)
valid_builds = builds.select do |build|
  build.processing_state == Spaceship::ConnectAPI::Build::ProcessingState::VALID
end
highest_valid_build = valid_builds.max_by { |build| build.version.to_i }
latest_released_build = if latest_released
                          valid_builds
                            .select { |build| build.app_version == latest_released.version_string }
                            .max_by { |build| build.version.to_i }
                        end

serialize_version = lambda do |version|
  next nil unless version

  {
    version: version.version_string,
    state: version.app_version_state,
    release_type: version.release_type,
    id: version.id,
  }
end

serialize_build = lambda do |build|
  next nil unless build

  app_version = begin
    build.app_version
  rescue StandardError
    nil
  end
  {
    build_number: build.version,
    app_version: app_version,
    state: build.processing_state,
    uploaded_date: build.uploaded_date,
    id: build.id,
  }
end

result = {
  bundle_id: bundle_id,
  app_id: app.id,
  latest_released: serialize_version.call(latest_released),
  latest_released_build: serialize_build.call(latest_released_build),
  highest_valid_build: serialize_build.call(highest_valid_build),
  draft_versions: versions
    .reject { |version| released_states.include?(version.app_version_state) }
    .sort_by { |version| Gem::Version.new(version.version_string) }
    .reverse
    .map { |version| serialize_version.call(version) },
}

puts JSON.pretty_generate(result)
