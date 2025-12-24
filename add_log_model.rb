#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CountryDaysTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first
app_group = project['CountryDaysTracker']
models_group = app_group['Models']

# Add LocationEventLog.swift
log_file = models_group.new_file('LocationEventLog.swift')
target.source_build_phase.add_file_reference(log_file)

project.save
puts "LocationEventLog.swift added to project!"
