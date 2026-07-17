require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
unless File.exist?(project_path)
  puts "Error: Xcode project not found at #{project_path}."
  exit 1
end

project = Xcodeproj::Project.open(project_path)
target_name = 'RunnerWidget'

# Check if target already exists to prevent duplicate adding
if project.targets.any? { |t| t.name == target_name }
  puts "Target '#{target_name}' already exists in Xcode project. Skipping setup."
  exit 0
end

# 1. Create the App Extension Target
widget_target = project.new_target(:app_extension, target_name, :ios, '14.0', nil, :swift)
puts "Created target '#{target_name}'."

# 2. Add files to the project group
widget_group = project.main_group.find_subpath(target_name, true)
widget_group.set_source_tree('SOURCE_ROOT')
widget_group.clear

swift_ref = widget_group.new_file('RunnerWidget/RunnerWidget.swift')
entitlements_ref = widget_group.new_file('RunnerWidget/RunnerWidget.entitlements')
info_plist_ref = widget_group.new_file('RunnerWidget/Info.plist')

# 3. Add Swift file to compiles sources build phase
widget_target.source_build_phase.add_file_reference(swift_ref)

# 4. Configure build settings for Debug and Release configurations
widget_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_NAME'] = 'RunnerWidget'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "com.example.myAutoGuide.RunnerWidget"
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = "RunnerWidget/RunnerWidget.entitlements"
  config.build_settings['INFOPLIST_FILE'] = "RunnerWidget/Info.plist"
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
  config.build_settings['SKIP_INSTALL'] = 'YES'
  config.build_settings['WRAPPER_EXTENSION'] = 'appex'
end

# 5. Link Widget Target as dependency in the main 'Runner' target
app_target = project.targets.find { |t| t.name == 'Runner' }
if app_target
  # Add reference for Runner.entitlements under the Runner group
  runner_group = project.main_group.find_subpath('Runner', true)
  if runner_group
    # Check if file reference already exists
    unless runner_group.files.any? { |f| f.path == 'Runner.entitlements' }
      runner_group.new_file('Runner.entitlements')
    end
  end
  app_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = "Runner/Runner.entitlements"
  end
  puts "Linked App Group entitlements to the main 'Runner' target."

  # Add Target Dependency
  dependency = project.new(Xcodeproj::Project::Object::PBXTargetDependency)
  dependency.target = widget_target
  app_target.dependencies << dependency
  
  # Find or create "Embed App Extensions" Copy Files build phase
  embed_phase = app_target.copy_files_build_phases.find { |p| p.symbol_dst_subfolder_spec == :plug_ins }
  unless embed_phase
    embed_phase = app_target.new_copy_files_build_phase
    embed_phase.symbol_dst_subfolder_spec = :plug_ins
    embed_phase.name = 'Embed App Extensions'
  end
  
  # Embed the widget target's build product (.appex)
  build_file = embed_phase.add_file_reference(widget_target.product_reference)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  puts "Linked '#{target_name}' target dependency inside 'Runner' target."
end

# Save changes
project.save
puts "Successfully saved modified Xcode project."
exit 0
