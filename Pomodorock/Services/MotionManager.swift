import Combine
import Foundation

#if os(iOS)
    import CoreMotion
#endif

// MARK: - Motion Manager (陀螺儀監聽器)
// 負責存取硬體陀螺儀資料，並將傾斜度資料推播給 View
class MotionManager: ObservableObject {
    @Published var tiltX: Double = 0
    @Published var tiltY: Double = 0

    #if os(iOS)
        private var motionManager = CMMotionManager()
    #endif

    init() {
        #if os(iOS)
            // 設定陀螺儀更新頻率，30Hz 已足夠，不需要太靈敏
            motionManager.gyroUpdateInterval = 1.0 / 30.0
            startMonitoring()
        #endif
    }

    private func startMonitoring() {
        #if os(iOS)
            guard motionManager.isGyroAvailable else {
                print("陀螺儀硬體不可用 (實機測試才有效)")
                return
            }

            motionManager.startGyroUpdates(to: .main) {
                [weak self] (data, error) in
                guard let self = self, let rotation = data?.rotationRate else {
                    return
                }

                DispatchQueue.main.async {
                    self.tiltX = rotation.x
                    self.tiltY = rotation.y
                }
            }
        #endif
    }

    deinit {
        #if os(iOS)
            motionManager.stopGyroUpdates()
        #endif
    }
}
