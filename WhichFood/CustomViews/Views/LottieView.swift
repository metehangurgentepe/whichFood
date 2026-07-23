import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let animation: LottieAnimation?
    var loopMode: LottieLoopMode = .loop
    @State private var playing: Bool = true
    
    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView()
        animationView.animation = animation
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        if playing {
            animationView.play()
        }
        return animationView
    }
    
    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        if playing {
            uiView.play()
        } else {
            uiView.pause()
        }
    }
    
    func playing(_ isPlaying: Bool = true) -> LottieView {
        var view = self
        view._playing = State(initialValue: isPlaying)
        return view
    }
} 