#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CountryDaysTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first
app_group = project['CountryDaysTracker']
views_group = app_group['Views']

# Create Onboarding group
onboarding_group = views_group.new_group('Onboarding', 'Onboarding')

# Add onboarding views
welcome_file = onboarding_group.new_file('WelcomeView.swift')
permission_file = onboarding_group.new_file('LocationPermissionView.swift')

target.source_build_phase.add_file_reference(welcome_file)
target.source_build_phase.add_file_reference(permission_file)

project.save
puts "Onboarding views added to project!"
