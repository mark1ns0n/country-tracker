#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CountryDaysTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first
app_group = project['CountryDaysTracker']
views_group = app_group['Views']

# Create view groups
root_group = views_group.new_group('Root', 'Root')
settings_group = views_group.new_group('Settings', 'Settings')

# Add view files
root_tab_file = root_group.new_file('RootTabView.swift')
settings_file = settings_group.new_file('SettingsView.swift')

target.source_build_phase.add_file_reference(root_tab_file)
target.source_build_phase.add_file_reference(settings_file)

project.save
puts "Root and Settings views added to project!"
