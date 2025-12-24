#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CountryDaysTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first
app_group = project['CountryDaysTracker']
views_group = app_group['Views']
vm_group = app_group['ViewModels']
cal_group = views_group['Calendar'] || views_group.new_group('Calendar', 'Calendar')

# Add files
cal_month = cal_group.new_file('CalendarMonthView.swift')
day_cell = cal_group.new_file('DayCellView.swift')
day_sheet = cal_group.new_file('DayDetailsSheet.swift')
vm_file = vm_group.new_file('CalendarViewModel.swift')

[target.source_build_phase, target.source_build_phase, target.source_build_phase, target.source_build_phase].zip([cal_month, day_cell, day_sheet, vm_file]).each do |phase, file|
  phase.add_file_reference(file)
end

project.save
puts 'Calendar views and view model added to project!'
