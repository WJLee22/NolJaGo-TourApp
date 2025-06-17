import UIKit

struct UITheme {
    // Colors
    static let primaryOrange = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
    static let lightOrange = UIColor(red: 1.0, green: 0.95, blue: 0.88, alpha: 1.0)
    static let backgroundGray = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
    static let textGray = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    static let secondaryTextGray = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
    static let placeholderGray = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
    
    // 진한 텍스트 색상
    static let primaryTextDark = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
    
    // Category Colors
    static let tourismBlue = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
    static let accommodationPurple = UIColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 1.0)
    static let restaurantRed = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
    static let festivalGreen = UIColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1.0)
    // Fonts
    static let titleFont = UIFont.boldSystemFont(ofSize: 20)
    static let subtitleFont = UIFont.systemFont(ofSize: 16, weight: .medium)
    static let bodyFont = UIFont.systemFont(ofSize: 15)
    static let captionFont = UIFont.systemFont(ofSize: 13, weight: .medium)
    static let tagFont = UIFont.systemFont(ofSize: 12, weight: .bold)
    
    // Spacing
    static let defaultPadding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    static let largePadding: CGFloat = 24
    
    // Corner Radius
    static let cardCornerRadius: CGFloat = 12
    static let buttonCornerRadius: CGFloat = 8
    static let tagCornerRadius: CGFloat = 12
    
    // Shadow
    static func applyShadow(to view: UIView, opacity: Float = 0.1, radius: CGFloat = 4, offset: CGSize = CGSize(width: 0, height: 2)) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = opacity
        view.layer.shadowRadius = radius
        view.layer.shadowOffset = offset
    }
    
    // Category Helper
    static func colorForCategory(_ contentTypeId: String) -> UIColor {
        switch contentTypeId {
        case "12": return tourismBlue      // 관광지
        case "32": return accommodationPurple  // 숙박
        case "39": return restaurantRed    // 음식점
        case "15": return festivalGreen    // 축제/행사
        default: return primaryOrange
        }
    }
    
    static func iconForCategory(_ category: String) -> String {
        switch category {
        case "관광지": return "mountain.2"
        case "숙박": return "bed.double"
        case "음식점": return "fork.knife"
        case "축제/행사": return "music.note"
        default: return "mappin"
        }
    }
}
