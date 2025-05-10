import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Image("img_bg")
                .resizable()
                .ignoresSafeArea()
            Image("img_120x48_logo_white")
                .resizable()
                .frame(width: 120, height: 48)
        }
    }
}

#Preview {
    SplashView()
}
