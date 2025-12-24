#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CountryDaysTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first
app_group = project['CountryDaysTracker']
storage_group = app_group['Storage']

# Add StayRepository.swift
repo_file = storage_group.new_file('StayRepository.swift')
target.source_build_phase.add_file_reference(repo_file)

project.save
puts "StayRepository.swift added to project!"
