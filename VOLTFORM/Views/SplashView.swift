import SwiftUI

struct SplashView: View {
    @State private var glow = false

    var body: some View {
        ZStack {
            Color.voltBlack.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.voltLime.opacity(glow ? 0.35 : 0.15))
                        .frame(width: 140, height: 140)
                        .blur(radius: 40)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(Color.voltLime)
                        .shadow(color: Color.voltLime.opacity(0.6), radius: glow ? 24 : 8)
                }
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: glow)

                HStack(spacing: 0) {
                    Text("VOLT")
                        .foregroundStyle(.white)
                    Text("FORM")
                        .foregroundStyle(Color.voltLime)
                }
                .font(.system(size: 40, weight: .heavy))
                .kerning(2)

                Text("Your body. Your recovery. Your plan.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))

                Spacer()
                Spacer()
            }
        }
        .onAppear { glow = true }
    }
}
