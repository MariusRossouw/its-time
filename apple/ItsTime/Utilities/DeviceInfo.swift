import Foundation

enum DeviceInfo {
    static var deviceId: String {
        if let existing = UserDefaults.standard.string(forKey: "its_time_device_id") {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "its_time_device_id")
        return newId
    }
}
