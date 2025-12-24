#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CountryDaysTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first
app_group = project['CountryDaysTracker']
models_group = app_group['Models']

# Add StayInterval.swift
stay_interval_file = models_group.new_file('StayInterval.swift')
target.source_build_phase.add_file_reference(stay_interval_file)

project.save
puts "StayInterval.swift added to project!"
