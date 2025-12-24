#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CountryDaysTracker.xcodeproj'
project = Xcodeproj::Project.new(project_path)

# Create main target
target = project.new_target(:application, 'CountryDaysTracker', :ios, '17.0')

# Get main group
main_group = project.main_group

# Create app group
app_group = main_group.new_group('CountryDaysTracker')
app_group.set_source_tree('<group>')
app_group.set_path('CountryDaysTracker')

# Add files to project
app_file = app_group.new_file('CountryDaysTrackerApp.swift')
content_file = app_group.new_file('ContentView.swift')
assets_file = app_group.new_file('Assets.xcassets')

# Add preview content group
preview_group = app_group.new_group('Preview Content')
preview_group.set_source_tree('<group>')
preview_group.set_path('Preview Content')
preview_assets = preview_group.new_file('Preview Assets.xcassets')

# Add files to build phases
target.source_build_phase.add_file_reference(app_file)
target.source_build_phase.add_file_reference(content_file)
target.resources_build_phase.add_file_reference(assets_file)
target.resources_build_phase.add_file_reference(preview_assets)

# Set build settings
target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.mark1ns0n.countrydays.dev'
  config.build_settings['DEVELOPMENT_ASSET_PATHS'] = '"CountryDaysTracker/Preview Content"'
  config.build_settings['ENABLE_PREVIEWS'] = 'YES'
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  config.build_settings['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['INFOPLIST_KEY_UIApplicationSceneManifest_Generation'] = 'YES'
  config.build_settings['INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents'] = 'YES'
  config.build_settings['INFOPLIST_KEY_UILaunchScreen_Generation'] = 'YES'
  config.build_settings['INFOPLIST_KEY_UISupportedInterfaceOrientations'] = 'UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight'
  config.build_settings['INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad'] = 'UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight'
end

# Set project settings
project.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
end

# Save project
project.save
puts "Xcode project created successfully!"
