import SwiftUI
import UIKit

private struct InteractivePopGestureModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(InteractivePopGestureRepresentable())
    }
}

private struct InteractivePopGestureRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        InteractivePopGestureController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let controller = uiViewController as? InteractivePopGestureController else { return }
        controller.enableGesture()
    }
}

private final class InteractivePopGestureController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enableGesture()
    }

    func enableGesture() {
        guard let navigationController = parentNavigationController() else { return }
        if let gesture = navigationController.interactivePopGestureRecognizer {
            gesture.isEnabled = true
            gesture.delegate = nil
        }
    }

    private func parentNavigationController() -> UINavigationController? {
        if let nav = navigationController {
            return nav
        }
        var parentVC = parent
        while parentVC != nil {
            if let nav = parentVC as? UINavigationController {
                return nav
            }
            parentVC = parentVC?.parent
        }
        return nil
    }
}

extension View {
    func enableSwipeBackGesture() -> some View {
        modifier(InteractivePopGestureModifier())
    }
}
