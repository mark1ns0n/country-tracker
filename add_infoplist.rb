#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CountryDaysTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

# Add Info.plist to project
app_group = project['CountryDaysTracker']
info_plist_file = app_group.new_file('Info.plist')

# Update build settings to use Info.plist
target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_FILE'] = 'CountryDaysTracker/Info.plist'
  config.build_settings.delete('GENERATE_INFOPLIST_FILE')
end

# Save project
project.save
puts "Info.plist added with location permissions!"
