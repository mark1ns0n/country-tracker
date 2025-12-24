#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CountryDaysTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first
app_group = project['CountryDaysTracker']
services_group = app_group['Services']

# Add service files
date_utils_file = services_group.new_file('DateUtils.swift')
aggregation_file = services_group.new_file('AggregationService.swift')

target.source_build_phase.add_file_reference(date_utils_file)
target.source_build_phase.add_file_reference(aggregation_file)

project.save
puts "DateUtils and AggregationService added to project!"
