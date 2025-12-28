import Foundation
import Combine

class FavoriteManager: ObservableObject {
    @Published var favorites: Set<String> = []

    private let userDefaultsKey = "favoriteProfiles"

    init() {
        loadFavorites()
    }

    private func loadFavorites() {
        if let data = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            favorites = Set(data)
        }
    }

    private func saveFavorites() {
        UserDefaults.standard.set(Array(favorites), forKey: userDefaultsKey)
    }

    func toggleFavorite(_ profileId: String) {
        var newFavorites = favorites
        if newFavorites.contains(profileId) {
            newFavorites.remove(profileId)
        } else {
            newFavorites.insert(profileId)
        }
        favorites = newFavorites
        saveFavorites()
    }

    func isFavorite(_ profileId: String) -> Bool {
        favorites.contains(profileId)
    }
}
