import SwiftUI

extension Color {
    static let adaptiveButtonColor: Color = Color(uiColor: UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor.systemBlue
        default:
            return UIColor.black
        }
    })
}
