# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: unicorn-cuba-base 1.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "unicorn-cuba-base"
  s.version = "1.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Jakub Pastuszek"]
  s.date = "2015-02-02"
  s.description = "web application base powered by Unicorn HTTP server and based on Cuba framework extended with additional Rack middleware and Cuba plugins"
  s.email = "jpastuszek@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    ".rspec",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "VERSION",
    "lib/unicorn-cuba-base.rb",
    "lib/unicorn-cuba-base/default_error_reporter.rb",
    "lib/unicorn-cuba-base/memory_limit.rb",
    "lib/unicorn-cuba-base/plugin/error_matcher.rb",
    "lib/unicorn-cuba-base/plugin/logging.rb",
    "lib/unicorn-cuba-base/plugin/memory_limit.rb",
    "lib/unicorn-cuba-base/plugin/response_helpers.rb",
    "lib/unicorn-cuba-base/rack/common_logger_xid.rb",
    "lib/unicorn-cuba-base/rack/error_handling.rb",
    "lib/unicorn-cuba-base/rack/memory_limit.rb",
    "lib/unicorn-cuba-base/rack/unhandled_request.rb",
    "lib/unicorn-cuba-base/rack/xid_logging.rb",
    "lib/unicorn-cuba-base/root_logger.rb",
    "lib/unicorn-cuba-base/stats.rb",
    "lib/unicorn-cuba-base/stats_reporter.rb",
    "lib/unicorn-cuba-base/uri_ext.rb",
    "spec/memory_limit_spec.rb",
    "spec/root_logger_spec.rb",
    "spec/spec_helper.rb",
    "unicorn-cuba-base.gemspec"
  ]
  s.homepage = "http://github.com/jpastuszek/unicorn-cuba-base"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.2.2"
  s.summary = "web appliaction base powered by Unicorn and Cuba"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<cuba>, ["~> 3.0"])
      s.add_runtime_dependency(%q<unicorn>, [">= 4.6.2"])
      s.add_runtime_dependency(%q<raindrops>, ["~> 0.11"])
      s.add_runtime_dependency(%q<cli>, ["~> 1.3"])
      s.add_runtime_dependency(%q<facter>, [">= 1.6.11"])
      s.add_runtime_dependency(%q<ruby-ip>, ["~> 0.9"])
      s.add_development_dependency(%q<rspec>, ["~> 2.13"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.9"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.8.4"])
      s.add_development_dependency(%q<capture-output>, ["~> 1.0"])
    else
      s.add_dependency(%q<cuba>, ["~> 3.0"])
      s.add_dependency(%q<unicorn>, [">= 4.6.2"])
      s.add_dependency(%q<raindrops>, ["~> 0.11"])
      s.add_dependency(%q<cli>, ["~> 1.3"])
      s.add_dependency(%q<facter>, [">= 1.6.11"])
      s.add_dependency(%q<ruby-ip>, ["~> 0.9"])
      s.add_dependency(%q<rspec>, ["~> 2.13"])
      s.add_dependency(%q<rdoc>, ["~> 3.9"])
      s.add_dependency(%q<jeweler>, ["~> 1.8.4"])
      s.add_dependency(%q<capture-output>, ["~> 1.0"])
    end
  else
    s.add_dependency(%q<cuba>, ["~> 3.0"])
    s.add_dependency(%q<unicorn>, [">= 4.6.2"])
    s.add_dependency(%q<raindrops>, ["~> 0.11"])
    s.add_dependency(%q<cli>, ["~> 1.3"])
    s.add_dependency(%q<facter>, [">= 1.6.11"])
    s.add_dependency(%q<ruby-ip>, ["~> 0.9"])
    s.add_dependency(%q<rspec>, ["~> 2.13"])
    s.add_dependency(%q<rdoc>, ["~> 3.9"])
    s.add_dependency(%q<jeweler>, ["~> 1.8.4"])
    s.add_dependency(%q<capture-output>, ["~> 1.0"])
  end
end

