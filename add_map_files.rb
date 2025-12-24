#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CountryDaysTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first
app_group = project['CountryDaysTracker']
views_group = app_group['Views']
services_group = app_group['Services']
vm_group = app_group['ViewModels']
res_group = app_group['Resources']
map_group = views_group['Map'] || views_group.new_group('Map', 'Map')

# Add files
geojson = res_group.new_file('world_countries_simplified.geojson')
country_store = services_group.new_file('CountryGeometryStore.swift')
range_vm = vm_group.new_file('RangeSelectionViewModel.swift')
map_vm = vm_group.new_file('MapViewModel.swift')
map_view = map_group.new_file('VisitedCountriesMapView.swift')

[target.resources_build_phase, target.source_build_phase, target.source_build_phase, target.source_build_phase, target.source_build_phase].zip([geojson, country_store, range_vm, map_vm, map_view]).each do |phase, file|
  phase.add_file_reference(file)
end

project.save
puts 'Map UI files added to project!'
