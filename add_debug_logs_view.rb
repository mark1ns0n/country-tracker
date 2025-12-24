#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CountryDaysTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first
app_group = project['CountryDaysTracker']
views_group = app_group['Views']

# Create Debug group
debug_group = views_group['Debug'] || views_group.new_group('Debug', 'Debug')
logs_file = debug_group.new_file('LogsView.swift')

target.source_build_phase.add_file_reference(logs_file)

project.save
puts 'Debug LogsView added to project!'
