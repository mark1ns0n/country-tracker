#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CountryDaysTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first
app_group = project['CountryDaysTracker']
engines_group = app_group['Engines']

# Add StayEngine.swift
engine_file = engines_group.new_file('StayEngine.swift')
target.source_build_phase.add_file_reference(engine_file)

project.save
puts "StayEngine.swift added to project!"
