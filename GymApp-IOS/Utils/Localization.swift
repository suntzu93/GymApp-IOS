import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case vietnamese = "vi"
    
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .vietnamese:
            return "Tiếng Việt"
        }
    }
    
    static var current: AppLanguage {
        get {
            guard let languageCode = UserDefaults.standard.string(forKey: "AppLanguage") else {
                return .english // Default language
            }
            return AppLanguage(rawValue: languageCode) ?? .english
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "AppLanguage")
            UserDefaults.standard.synchronize()
            
            // Update the app's language
            Bundle.setLanguage(newValue.rawValue)
        }
    }
}

extension Bundle {
    private static var bundle: Bundle?
    
    static func setLanguage(_ language: String) {
        let path = Bundle.main.path(forResource: language, ofType: "lproj")
        bundle = path != nil ? Bundle(path: path!) : nil
    }
    
    static func localizedBundle() -> Bundle {
        return bundle ?? Bundle.main
    }
} 