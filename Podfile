# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'WhichFood' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

post_install do |installer|
      installer.pods_project.targets.each do |target|
          target.build_configurations.each do |config|
          xcconfig_path = config.base_configuration_reference.real_path
          xcconfig = File.read(xcconfig_path)
          xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
          File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
          end
      end
  end

  # Pods for WhichFood
pod 'FirebaseAnalytics'
pod 'FirebaseAuth'
pod 'FirebaseFirestore'
pod 'FirebaseFirestoreSwift'
pod 'FirebaseFunctions'	
pod 'FirebaseMessaging'	
pod 'FirebaseStorage'	
pod 'FirebasePerformance'	
pod 'FirebaseDatabase'	
pod 'Alamofire'
pod 'OpenAISwift'
pod 'OpenAIKit'
pod 'GooglePlaces', '8.2.0'
pod 'RxSwift', '6.5.0'
pod 'RxCocoa', '6.5.0'


  target 'WhichFoodTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'WhichFoodUITests' do
    # Pods for testing
  end

end
