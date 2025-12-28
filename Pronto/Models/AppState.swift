import Foundation
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSettings = false
}
