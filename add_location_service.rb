#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CountryDaysTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first
app_group = project['CountryDaysTracker']
services_group = app_group['Services']

# Add LocationService.swift
service_file = services_group.new_file('LocationService.swift')
target.source_build_phase.add_file_reference(service_file)

project.save
puts "LocationService.swift added to project!"
