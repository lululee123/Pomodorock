import SwiftUI
import AuthenticationServices

struct SideMenuPanel: View {
    @Environment(UserStore.self) private var user
    
    @State private var auth = AuthManager()
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        
        @Bindable var user = user
      
        VStack(alignment: .leading, spacing: 24) {
            Text(user(.settings))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.appTextPrimary)
            
            if auth.isSignedIn {
                Button(user(.signOut), role: .destructive) {
                    auth.signOut()
                }
                .font(.subheadline)
            } else {
//                SignInWithAppleButton(.signIn) { request in
//                    auth.configureAppleRequest(request)
//                } onCompletion: { result in
//                    auth.handleAppleSignIn(result)
//                }
//                .signInWithAppleButtonStyle(
//                    colorScheme == .dark ? .white : .black
//                )
//                .frame(height: 44)
//                .clipShape(Capsule())
            }
            
            Divider()
            
            // Pomodoro
            Toggle(isOn: $user.pomodoroMode.animation()) {
                Text(user(.pomodoroMode))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.appTextPrimary)
            }
            .tint(user.accent)
            
            Divider()
            
            // 目標日期開關
            Toggle(isOn: $user.targetDateEnabled.animation()) {
                Text(user(.targetDate))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.appTextPrimary)
            }
            .tint(user.accent)
            
            Divider()
            
            // color theme
            HStack {
                ColorPicker(
                    user(.rockThemeColor),
                    selection: $user.accent,
                    supportsOpacity: false
                )
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.appTextPrimary)
                
                Button {
                    withAnimation { user.resetAccent() }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline)
                        .foregroundColor(Color.appTextSecondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // theme
            HStack {
                Text(user(.appearance))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.appTextPrimary)
                
                Spacer()
                
                Picker("", selection: $user.appearance) {
                    ForEach(AppAppearance.allCases) { mode in
                        Text(mode.displayName(user.language)).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .tint(user.accent)
            }
            
            Divider()
            
            // lang
            HStack {
                Text(user(.language))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.appTextPrimary)
                
                Spacer()
                
                Picker("", selection: $user.language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .tint(user.accent)
            }
            
            Spacer()
        }
        .padding(24)
        .padding(.top, 44)
        .frame(width: 280)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.appBackground)
        .clipShape(
            .rect(bottomTrailingRadius: 24, topTrailingRadius: 24)
        )
        .shadow(color: .black.opacity(0.15), radius: 12, x: 4)
        .ignoresSafeArea()
        
    }
}
