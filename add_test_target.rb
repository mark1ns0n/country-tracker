#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CountryDaysTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

app_target = project.targets.find { |t| t.name == 'CountryDaysTracker' }
raise 'App target not found' unless app_target

# Create tests target
tests_target = project.new_target(:unit_test_bundle, 'CountryDaysTrackerTests', :ios, '17.0')

# Add files to test target
app_group = project['CountryDaysTracker']
tests_group = app_group['Tests'] || app_group.new_group('Tests', 'Tests')

stay_tests = tests_group.new_file('StayEngineTests.swift')
agg_tests = tests_group.new_file('AggregationServiceTests.swift')

[stay_tests, agg_tests].each { |f| tests_target.source_build_phase.add_file_reference(f) }

# Set product bundle ID and settings
['Debug','Release'].each do |cfg|
  cfg_obj = tests_target.build_configurations.find { |c| c.name == cfg }
  cfg_obj.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.mark1ns0n.countrydays.devTests'
  cfg_obj.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  cfg_obj.build_settings['SWIFT_VERSION'] = '5.0'
  cfg_obj.build_settings['TEST_HOST'] = ''
  cfg_obj.build_settings['BUNDLE_LOADER'] = ''
end

# Add test target dependency
app_dep = tests_target.add_dependency(app_target)

# Add to scheme? (creating a basic shared scheme is more complex; relying on Xcode auto)

project.save
puts 'Unit test target created and files added!'
