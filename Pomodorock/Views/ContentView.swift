import AuthenticationServices
import Combine
import SwiftUI

// MARK: - ContentView (主計時畫面與 Layout)
struct ContentView: View {
    // --- 倒數計時狀態控制 ---
    // 專注分鐘數，計時未開始時可點數字調整 (不持久化，重開回預設)
    @State private var focusMinutes: Int = TimerConfig.focusMinutes
    @State private var timeRemaining: TimeInterval = TimerConfig.focusDuration
    @State private var isTimerRunning = false

    private var totalTime: TimeInterval { Double(focusMinutes) * 60 }

    // 分鐘可選範圍 (自由選)
    private let minuteRange = 1...300

    // 分鐘選擇滾輪
    @State private var showMinutePicker = false

    // 目標日選擇
    @State private var showTargetDatePicker = false

    // --- Apple 登入 (未來帳號連結用) ---
    @State private var auth = AuthManager()

    // --- 廢話資料來源 (遠端 + 本地 fallback) ---
    @Environment(QuoteStore.self) private var quoteStore

    // --- 使用者狀態 ---
    @Environment(UserStore.self) private var user

    // --- 側邊選單 ---
    @State private var showSideMenu = false

    // theme
    @Environment(\.colorScheme) private var colorScheme

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // --- 廢話氣泡 ---
    @State private var showSpeechBubble = false
    @State private var currentQuote = ""
    @State private var bubbleDismissTask: Task<Void, Never>?

    // 氣泡停留秒數
    private let tapQuoteDuration: TimeInterval = 3
    private let finishQuoteDuration: TimeInterval = 4

    // 動態計算倒數進度比例 (1.0 -> 0.0)
    var progress: Double {
        return timeRemaining / totalTime
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header (陪伴天數)
                headerView
                    .padding(.horizontal)
                    .padding(.top, 8)

                Spacer()

                ZStack {
                    if user.pomodoroMode {
                        Circle()
                            .stroke(Color.appRingTrack, lineWidth: 12)
                            .frame(width: 270, height: 270)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                user.accent,
                                style: StrokeStyle(
                                    lineWidth: 12,
                                    lineCap: .round
                                )
                            )
                            .frame(width: 270, height: 270)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: progress)
                    }

                    ZStack {
                        RealRockView()

                        GooglyEyesView()
                            // 眼睛位置微調讓它貼合石头表面
                            .offset(y: -10)
                    }
                    // 廢話氣泡
                    .overlay(alignment: .top) {
                        if showSpeechBubble {
                            Text(currentQuote)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.appTextPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.appSurface)
                                .cornerRadius(12)
                                .shadow(radius: 4, x: 1, y: 2)
                                .transition(.scale.combined(with: .opacity))
                                .offset(y: -20)
                        }
                    }
                    .onTapGesture {
                        // Pomodoro not show
                        guard !user.pomodoroMode else { return }

                        // 戳石頭時更換金句
                        currentQuote = quoteStore.randomQuote(
                            for: user.language
                        )

                        Feedback.strongHaptic()

                        showQuoteTemporarily(for: tapQuoteDuration)
                    }
                }

                if user.pomodoroMode {
                    VStack(spacing: 4) {
                        if isTimerRunning {
                            timeText
                        } else {
                            // 未開始：點數字用滾輪自由選擇分鐘數
                            Button {
                                showMinutePicker = true
                            } label: {
                                timeText
                            }
                            .buttonStyle(.plain)
                        }

                        Text(isTimerRunning ? user(.focusingSubtitle) : "")
                            .font(.caption)
                            .foregroundColor(Color.appTextSecondary)
                    }
                    .padding(.top, 32)

                    HStack(spacing: 16) {
                        // reset
                        if !isTimerRunning {
                            Button(action: resetTimer) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                                    .frame(width: 50, height: 50)
                                    .background(Color.appSurface)
                                    .clipShape(Circle())
                                    .shadow(
                                        color: .black.opacity(0.05),
                                        radius: 4
                                    )
                            }
                        }

                        // Play / Pause
                        Button(action: toggleTimer) {
                            HStack {
                                Image(
                                    systemName: isTimerRunning
                                        ? "pause.fill" : "play.fill"
                                )
                                Text(
                                    isTimerRunning
                                        ? user(.pause) : user(.startFocus)
                                )
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(user.accent)
                            .clipShape(Capsule())
                            .shadow(
                                color: user.accent.opacity(0.3),
                                radius: 8,
                                y: 4
                            )
                        }
                    }
                    .padding(.top, 24)
                }

                Spacer()
            }

            sideMenuOverlay
        }
        .onReceive(timer) { _ in
            guard isTimerRunning else { return }

            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timerFinished()
            }
        }
        .task {
            await user.start()
            await quoteStore.loadRemoteQuotes()
        }
        .preferredColorScheme(user.preferredColorScheme)
        .onChange(of: focusMinutes) {
            // 未開始時，調整分鐘數同步歸位剩餘時間
            if !isTimerRunning {
                timeRemaining = totalTime
            }
        }
        .sheet(isPresented: $showMinutePicker) {
            minutePickerSheet
        }
        .sheet(isPresented: $showTargetDatePicker) {
            targetDatePickerSheet
        }
    }

    // 目標日期選擇器
    private var targetDatePickerSheet: some View {
        @Bindable var user = user

        return VStack(spacing: 16) {
            DatePicker(
                "",
                selection: Binding(
                    get: { user.targetDate ?? Date() },
                    set: { user.targetDate = $0 }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .tint(user.accent)
            .padding(.horizontal)

            Button {
                showTargetDatePicker = false
            } label: {
                Text(user(.done))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(user.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .presentationDetents([.medium, .large])
    }

    // 分鐘數滾輪選擇器
    private var minutePickerSheet: some View {
        VStack(spacing: 16) {
            Picker("", selection: $focusMinutes) {
                ForEach(minuteRange, id: \.self) { minutes in
                    Text(minuteLabel(minutes)).tag(minutes)
                }
            }
            .labelsHidden()
            .pickerStyle(.wheel)

            Button {
                showMinutePicker = false
            } label: {
                Text(user(.done))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(user.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .presentationDetents([.medium])
    }

    private var headerView: some View {
        HStack {
            Button {
                showSideMenu = true
            } label: {
                companionBadgeLabel
            }
            .buttonStyle(.plain)

            Spacer()

            // 目標日開關開啟時，右上角顯示可點的目標日 label
            if user.targetDateEnabled {
                Button {
                    showTargetDatePicker = true
                } label: {
                    targetDateBadgeLabel
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var companionBadgeLabel: some View {
        Text(
            user(.companionDays(user.companionDays))
        )
        .font(.caption)
        .fontWeight(.bold)
        .foregroundColor(user.accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.appRingTrack)
        .clipShape(Capsule())
    }

    // 目標日倒數 label：未設 → 提示；未到 → 還有 N 天；已到 → 已達成
    private var targetDateBadgeLabel: some View {
        Text(targetBadgeText)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(user.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.appRingTrack)
            .clipShape(Capsule())
    }

    private var targetBadgeText: String {
        guard user.targetDate != nil else { return user(.setTargetDate) }
        return user.targetDays > 0
            ? user(.targetDays(user.targetDays))
            : user(.targetReached)
    }

    private var sideMenuOverlay: some View {
        ZStack(alignment: .leading) {
            // 半透明遮罩，點擊關閉
            Color.black
                .opacity(showSideMenu ? 0.25 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(showSideMenu)
                .onTapGesture { showSideMenu = false }

            sideMenuPanel
                .offset(x: showSideMenu ? 0 : -320)
        }
        .animation(
            .spring(response: 0.35, dampingFraction: 0.85),
            value: showSideMenu
        )
    }

    private var sideMenuPanel: some View {
        @Bindable var user = user

        return VStack(alignment: .leading, spacing: 24) {
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
                SignInWithAppleButton(.signIn) { request in
                    auth.configureAppleRequest(request)
                } onCompletion: { result in
                    auth.handleAppleSignIn(result)
                }
                .signInWithAppleButtonStyle(
                    colorScheme == .dark ? .white : .black
                )
                .frame(height: 44)
                .clipShape(Capsule())
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

    private func toggleTimer() {
        withAnimation {
            isTimerRunning.toggle()
        }
    }

    private func resetTimer() {
        withAnimation {
            isTimerRunning = false
            timeRemaining = totalTime
        }
    }

    private func timerFinished() {
        isTimerRunning = false
        currentQuote = user(.focusCompleted)

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            timeRemaining = totalTime
        }

        Feedback.playCompletionSound()

        if !user.pomodoroMode {
            showQuoteTemporarily(for: finishQuoteDuration)
        }
    }

    private func showQuoteTemporarily(for duration: TimeInterval) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
            showSpeechBubble = true
        }

        // 取消前一個排程，避免多次點擊時提前隱藏
        bubbleDismissTask?.cancel()
        bubbleDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            withAnimation {
                showSpeechBubble = false
            }
        }
    }

    // 格式化時間 (將秒數轉為 MM:SS 格式)
    private func timeFormatted(_ totalSeconds: TimeInterval) -> String {
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // 大字計時顯示
    private var timeText: some View {
        Text(timeFormatted(timeRemaining))
            .font(.system(size: 44, weight: .bold, design: .monospaced))
            .foregroundColor(Color.appTextPrimary)
    }

    // 分鐘標籤
    private func minuteLabel(_ minutes: Int) -> String {
        user.language == .en ? "\(minutes) min" : "\(minutes) 分鐘"
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(QuoteStore())
            .environment(UserStore(sync: LocalUserSyncService()))
    }
}
