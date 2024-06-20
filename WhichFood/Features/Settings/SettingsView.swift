//
//  SettingsView.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 29.02.2024.
//

import Foundation
import SwiftUI
import MessageUI

struct UIKitDestinationView: UIViewControllerRepresentable {
    var view: UIViewController!
    func makeUIViewController(context: Context) -> UIViewController {
        let navigationViewController = UINavigationController(rootViewController: view)
        return navigationViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}

struct SettingsView: View {
    @State private var darkMode = false
    @State private var isPremiumVCPresented = false
    @State private var isAccountVCPresented = false
    @State private var sendEmail = false
    @State private var showAlert = false
    private var appStoreURL: URL {
        let appStoreURLString = Constants.Links.appStoreLink.rawValue.locale()
        return URL(string: appStoreURLString)!
    }
    private var eventierURL: URL {
        let appStoreURLString = Constants.Links.eventierLink.rawValue.locale()
        return URL(string: appStoreURLString)!
    }
    private var privacyPolicyURL: URL {
        let appStoreURLString = Constants.Links.privacyPolicy.rawValue.locale()
        return URL(string: appStoreURLString)!
    }
    private var termsOfServiceURL: URL {
        let appStoreURLString = Constants.Links.termsOfService.rawValue.locale()
        return URL(string: appStoreURLString)!
    }
    @State private var showRestartAlert = false

    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text(LocaleKeys.Settings.accountSettings.rawValue.locale())) {
                    Button(action: {
                        isAccountVCPresented = true
                    }, label: {
                        HStack {
                            Image(systemName: "person")
                                .foregroundStyle(.foreground)
                            Text(LocaleKeys.Settings.account.rawValue.locale())
                                .foregroundStyle(.foreground)
                        }
                    })
                    .sheet(isPresented: $isAccountVCPresented, content: {
                        UIKitDestinationView(view: AccountViewController())
                    })
                    
                    Menu {
                        Button(action: {changeAppLanguage(to: "es")}, label: {
                            Text(LocaleKeys.Languages.spanish.rawValue.locale())
                        })
                        Button(action: {changeAppLanguage(to: "tr")}, label: {
                            Text(LocaleKeys.Languages.turkish.rawValue.locale())
                        })
                        Button(action: {changeAppLanguage(to: "cs")}, label: {
                            Text(LocaleKeys.Languages.czech.rawValue.locale())
                        })
                        Button(action: {changeAppLanguage(to: "fr")}, label: {
                            Text(LocaleKeys.Languages.french.rawValue.locale())
                        })
                        Button(action: {changeAppLanguage(to: "en")}, label: {
                            Text(LocaleKeys.Languages.english.rawValue.locale())
                        })
                        Button(action: {changeAppLanguage(to: "de")}, label: {
                            Text(LocaleKeys.Languages.german.rawValue.locale())
                        })
                        Button(action: {changeAppLanguage(to: "it")}, label: {
                            Text(LocaleKeys.Languages.italian.rawValue.locale())
                        })
                        Button(action: {changeAppLanguage(to: "ru")}, label: {
                            Text(LocaleKeys.Languages.russian.rawValue.locale())
                        })
                        Button(action: {changeAppLanguage(to: "ar")}, label: {
                            Text(LocaleKeys.Languages.arabic.rawValue.locale())
                        })
                        Button(action: {changeAppLanguage(to: "fa-IR")}, label: {
                            Text(LocaleKeys.Languages.iranian.rawValue.locale())
                        })
                    } label: {
                        HStack {
                            Image(systemName: "network")
                                .foregroundStyle(.foreground)
                            Text(LocaleKeys.Settings.language.rawValue.locale())
                                .foregroundStyle(.foreground)
                            Spacer()
                        }
                    }
                    .alert(isPresented: $showRestartAlert) {
                        Alert(
                            title: Text(LocaleKeys.Settings.languageChange.rawValue.locale()),
                            message: Text(LocaleKeys.Settings.applyChange.rawValue.locale()),
                            primaryButton: .default(Text(LocaleKeys.Settings.okButton.rawValue.locale()), action: {
                                exit(0)
                            }),
                            secondaryButton: .cancel()
                        )
                    }
                }
                
                
                Section(header: Text(LocaleKeys.Settings.support.rawValue.locale())) {
                    Button(action: {
                        isPremiumVCPresented = true
                    }) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(Color.yellow)
                            Text("Premium")
                                .foregroundStyle(.foreground)
                        }
                    }
                    .sheet(isPresented: $isPremiumVCPresented, content: {
                        UIKitDestinationView(view: PremiumVC())
                    })
                    
                    Button(action: {
                        if MFMailComposeViewController.canSendMail() {
                            sendEmail.toggle()
                        } else {
                            showAlert.toggle()
                        }
                        
                    }, label: {
                        HStack{
                            Image(systemName: "heart")
                                .foregroundStyle(.foreground)
                            Text(LocaleKeys.Settings.giveFeedback.rawValue.locale())
                                .foregroundStyle(.foreground)
                        }
                    })
                    .sheet(isPresented: $sendEmail, content: {
                        MailView(content: LocaleKeys.Settings.hello.rawValue.locale(), to: Constants.Links.email.rawValue, subject: LocaleKeys.Settings.aboutApp.rawValue.locale())
                    })
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text(LocaleKeys.Settings.mailMessageError.rawValue.locale()))
                    }
                    
                    
                    HStack{
                        Image(systemName: "highlighter")
                        Link(destination: appStoreURL, label: {
                            Text(LocaleKeys.Settings.writeComment.rawValue.locale())
                                .foregroundStyle(.foreground)
                        })
                    }
                    
                    HStack{
                        Image(systemName: "square.and.arrow.up")
                        Button(LocaleKeys.Settings.share.rawValue.locale()) {
                            shareApp()
                        }
                        .foregroundStyle(.foreground)
                    }
                }
                
                Section(header: Text(LocaleKeys.Settings.appearence.rawValue.locale())) {
                    HStack{
                        Image(systemName: "moon.stars")
                        Text(LocaleKeys.Settings.darkMode.rawValue.locale())
                        Spacer()
                        Toggle(isOn: $darkMode, label: {
                            
                        }).onChange(of: $darkMode.wrappedValue) { newValue in
                            setDarkMode()
                        }
                    }
                }
                
                Section(header: Text(LocaleKeys.Settings.otherApps.rawValue.locale())) {
                    HStack{
                        Image("Eventier")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Link(destination: eventierURL, label: {
                            Text("Eventier")
                                .foregroundStyle(.foreground)
                        })
                    }
                }
                
                Section(header: Text(LocaleKeys.Settings.rightAndPrivacy.rawValue.locale())) {
                    HStack{
                        Image(systemName: "lock.circle.fill")
                        Link(destination: privacyPolicyURL, label: {
                            Text(LocaleKeys.Settings.privacyPolicy.rawValue.locale())
                                .foregroundStyle(.foreground)
                        })
                    }
                    
                    HStack{
                        Image(systemName: "doc.text")
                        Link(destination: termsOfServiceURL, label: {
                            Text(LocaleKeys.Settings.termsOfService.rawValue.locale())
                                .foregroundStyle(.foreground)
                        })
                    }
                    
                }
                .onAppear {
                    initDarkMode()
                }
                .navigationTitle(LocaleKeys.Settings.title.rawValue.locale())
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    
    private func shareApp() {
        let appStoreURLString = Constants.Links.appStoreLink.rawValue
        let appStoreURL = URL(string: appStoreURLString)!
        
        let activityViewController = UIActivityViewController(activityItems: [appStoreURL], applicationActivities: nil)
        
        if let topViewController = UIApplication.shared.windows.first?.rootViewController?.topMostViewController() {
            topViewController.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    
    private func initDarkMode() {
        if UserDefaults.standard.string(forKey: "themeMode") == "light" {
            darkMode = false
        } else {
            darkMode = true
        }
    }
    
    
    func setDarkMode() {
        if darkMode {
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = .dark
            }
            UserDefaults.standard.set("dark", forKey: "themeMode")
        } else {
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = .light
            }
            UserDefaults.standard.set("light", forKey: "themeMode")
        }
    }
    
    
    func changeAppLanguage(to languageCode: String) {
        showRestartAlert = true
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
}

#Preview {
    SettingsView()
}


