import SwiftUI

// MARK: - GooglyEyesView
struct GooglyEyesView: View {
    @ObservedObject var motion = MotionManager()

    // 眼框的半徑
    private let eyeFrameRadius: CGFloat = 16
    // 黑眼珠的半徑
    private let pupilRadius: CGFloat = 8

    // 黑眼珠相對眼框中心的當前位置
    @State private var pupilPosition: CGPoint = .zero

    // 數值愈小愈滑動，滑順靈活
    private let frictionConstant: CGFloat = 0.96

    // 數值愈大，眼珠隨手機傾斜的距離愈大。
    private let tiltSensitivity: CGFloat = 10.0

    var body: some View {
        HStack(spacing: 12) {
            singleEyeView
            singleEyeView
        }
        .onAppear {
            setupPhysicsLoop()
        }
    }

    private var singleEyeView: some View {
        ZStack {
            // 白眼框
            Circle()
                .fill(Color.white)
                .frame(width: eyeFrameRadius * 2, height: eyeFrameRadius * 2)
                .shadow(color: .black.opacity(0.15), radius: 2, x: 1, y: 1)

            // 黑眼珠
            Circle()
                .fill(Color.black)
                .frame(width: pupilRadius * 2, height: pupilRadius * 2)
                .offset(x: pupilPosition.x, y: pupilPosition.y)
                // 阻尼感：使用 spring 動畫平滑移動
                .animation(
                    .spring(
                        response: 0.15,
                        dampingFraction: 0.3,
                        blendDuration: 0
                    ),
                    value: pupilPosition
                )
        }
    }

    private func setupPhysicsLoop() {
        Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            let targetX = motion.tiltY * tiltSensitivity
            let targetY = motion.tiltX * tiltSensitivity

            let dx = targetX - pupilPosition.x
            let dy = targetY - pupilPosition.y

            var nextX = pupilPosition.x + dx * (1.0 - frictionConstant)
            var nextY = pupilPosition.y + dy * (1.0 - frictionConstant)

            // 碰撞限制
            let maxBoundary = eyeFrameRadius - pupilRadius - 1
            let distToCenter = sqrt(nextX * nextX + nextY * nextY)

            if distToCenter > maxBoundary {
                let scale = maxBoundary / distToCenter
                nextX *= scale
                nextY *= scale
            }

            self.pupilPosition = CGPoint(x: nextX, y: nextY)
        }
    }
}
