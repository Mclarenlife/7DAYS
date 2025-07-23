import SwiftUI

struct FloatingAddButton: View {
    let action: () -> Void
    @State private var isPressed = false
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPressed = false
                    action()
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: 136, height: 46)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                }
                .scaleEffect(isPressed ? 0.85 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("添加待办")
            Spacer()
        }
    }
} 