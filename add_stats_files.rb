#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CountryDaysTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first
app_group = project['CountryDaysTracker']
views_group = app_group['Views']
vm_group = app_group['ViewModels']
stats_group = views_group['Stats'] || views_group.new_group('Stats', 'Stats')

# Add files
stats_vm = vm_group.new_file('StatsViewModel.swift')
stats_view = stats_group.new_file('StatsView.swift')

[target.source_build_phase, target.source_build_phase].zip([stats_vm, stats_view]).each do |phase, file|
  phase.add_file_reference(file)
end

project.save
puts 'Stats files added to project!'
