# frozen_string_literal: true

require_relative "lib/cbor/version"

Gem::Specification.new do |spec|
  spec.name = "cbor.rb"
  spec.version = CBOR::VERSION
  spec.authors = ["Vito Sartori"]
  spec.email = ["hey@vito.io"]
  spec.licenses = "MIT"

  spec.summary = "Pure-Ruby implementation of CBOR"
  spec.description = spec.summary
  spec.homepage = "https://github.com/heyvito/cbor.rb"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.metadata["rubygems_mfa_required"] = "true"
end
