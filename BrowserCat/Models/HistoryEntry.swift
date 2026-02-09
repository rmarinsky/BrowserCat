import Foundation

struct HistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let url: String
    let domain: String
    let title: String?
    let appName: String
    let profileName: String?
    let openedAt: Date

    init(id: UUID = UUID(), url: String, domain: String, title: String?, appName: String, profileName: String?, openedAt: Date = Date()) {
        self.id = id
        self.url = url
        self.domain = domain
        self.title = title
        self.appName = appName
        self.profileName = profileName
        self.openedAt = openedAt
    }
}
