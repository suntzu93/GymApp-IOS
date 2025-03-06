import SwiftUI

struct ToastView: View {
    let message: String
    let isSuccess: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundColor(isSuccess ? .green : .red)
                .font(.system(size: 24))
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button(action: {
                onDismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.8))
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

// This is a simpler direct implementation without using ViewModifier
struct ToastOverlay: View {
    @Binding var isShowing: Bool
    let message: String
    let isSuccess: Bool
    let duration: TimeInterval
    
    var body: some View {
        if isShowing {
            VStack {
                ToastView(
                    message: message,
                    isSuccess: isSuccess,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowing = false
                        }
                    }
                )
                .padding(.top, 10)
                
                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                print("Toast appeared with message: \(message)")
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowing = false
                    }
                }
            }
            .onDisappear {
                print("Toast disappeared")
            }
            .zIndex(999) // Ensure it's above everything
        }
    }
}

// Keep the modifier for backward compatibility
struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let isSuccess: Bool
    let duration: TimeInterval
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            ToastOverlay(
                isShowing: $isShowing,
                message: message,
                isSuccess: isSuccess,
                duration: duration
            )
        }
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String, isSuccess: Bool = true, duration: TimeInterval = 2.0) -> some View {
        self.modifier(ToastModifier(isShowing: isShowing, message: message, isSuccess: isSuccess, duration: duration))
    }
}

struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ToastView(message: "Meal deleted successfully", isSuccess: true, onDismiss: {})
                .padding(.bottom)
            
            ToastView(message: "Failed to delete meal", isSuccess: false, onDismiss: {})
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
} 