#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CountryDaysTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find and remove old file references
app_group = project['CountryDaysTracker']
app_group.files.each { |f| f.remove_from_project if f.path =~ /\.swift$/ }

# Create folder structure
folders = ['App', 'Models', 'Services', 'Storage', 'Engines', 'ViewModels', 'Views', 'Resources', 'Tests']

target = project.targets.first

folders.each do |folder_name|
  folder_group = app_group.new_group(folder_name, folder_name)
  
  if folder_name == 'App'
    # Add existing files in App folder
    app_file = folder_group.new_file('CountryDaysTrackerApp.swift')
    content_file = folder_group.new_file('ContentView.swift')
    target.source_build_phase.add_file_reference(app_file)
    target.source_build_phase.add_file_reference(content_file)
  end
end

# Save project
project.save
puts "Project structure updated successfully!"
