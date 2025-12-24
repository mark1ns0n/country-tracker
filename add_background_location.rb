#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CountryDaysTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

# Add entitlements file
app_group = project['CountryDaysTracker']
entitlements_file = app_group.new_file('CountryDaysTracker.entitlements')

# Set entitlements path in build settings
target.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'CountryDaysTracker/CountryDaysTracker.entitlements'
end

# Save project
project.save
puts "Background Location capability added!"
