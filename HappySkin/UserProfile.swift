//
//  UserProfile.swift
//  HappySkin
//

import Foundation

struct UserProfile: Equatable {
    var displayName: String
    var skinType: String
    var preferredLanguage: String
    var notificationsEnabled: Bool
    var email: String
    var updatedAt: Date

    static func defaults(email: String, fallbackName: String) -> UserProfile {
        UserProfile(
            displayName: fallbackName,
            skinType: "normal",
            preferredLanguage: "es",
            notificationsEnabled: true,
            email: email,
            updatedAt: Date()
        )
    }
}