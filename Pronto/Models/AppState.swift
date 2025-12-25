//
//  AppState.swift
//  Pronto
//
//  앱 전역 상태 관리
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showSettings: Bool = false

    func showError(_ message: String) {
        self.errorMessage = message
    }

    func clearError() {
        self.errorMessage = nil
    }

    func setLoading(_ loading: Bool) {
        self.isLoading = loading
    }
}
