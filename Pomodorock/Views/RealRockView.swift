import SwiftUI

// MARK: - RealRockView (寫實石頭身軀)
struct RealRockView: View {
    var body: some View {
        Image("real_rock_texture")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 200, height: 200)
    }
}
