//
//  SkinScanHistoryViewModel.swift
//  HappySkin
//

import Foundation
import FirebaseAuth

@MainActor
final class SkinScanHistoryViewModel: ObservableObject {
    @Published var scans: [SkinScanRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let store = FirestoreSkinScanStore.shared

    var latestScan: SkinScanRecord? {
        scans.first
    }

    func refresh(for user: User?) async {
        guard let user else {
            scans = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            scans = try await store.fetchRecentScans(for: user, limit: 20)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
