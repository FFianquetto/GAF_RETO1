//
//  FirestoreUserProfileStore.swift
//  HappySkin
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum FirestoreUserProfileError: LocalizedError {
    case permissionDenied
    case invalidServerResponse
    case requestFailed(message: String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "No tienes permisos para guardar el perfil. Revisa las reglas de Firestore para Users/{uid}."
        case .invalidServerResponse:
            return "La respuesta de Firestore no es valida."
        case let .requestFailed(message):
            return "No se pudo completar la operacion en Firestore: \(message)"
        }
    }
}

actor FirestoreUserProfileStore {
    static let shared = FirestoreUserProfileStore()

    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func fetchOrCreateProfile(for user: User, fallbackName: String) async throws -> UserProfile {
        let documentReference = db.collection("Users").document(user.uid)

        do {
            let snapshot = try await getDocument(documentReference)
            if let data = snapshot.data(), snapshot.exists {
                return profile(from: data, user: user, fallbackName: fallbackName)
            }

            let defaultProfile = UserProfile.defaults(email: user.email ?? "", fallbackName: fallbackName)
            try await saveProfile(defaultProfile, for: user)
            return defaultProfile
        } catch {
            throw mapFirestoreError(error)
        }
    }

    func saveProfile(_ profile: UserProfile, for user: User) async throws {
        let documentReference = db.collection("Users").document(user.uid)
        let data = firestoreDocumentData(from: profile)

        do {
            try await setDocument(documentReference, data: data)
        } catch {
            throw mapFirestoreError(error)
        }
    }

    private func firestoreDocumentData(from profile: UserProfile) -> [String: Any] {
        return [
            "displayName": profile.displayName,
            "skinType": profile.skinType,
            "preferredLanguage": profile.preferredLanguage,
            "notificationsEnabled": profile.notificationsEnabled,
            "email": profile.email,
            "updatedAt": Timestamp(date: Date()),
        ]
    }

    private func profile(from data: [String: Any], user: User, fallbackName: String) -> UserProfile {
        let displayName = data["displayName"] as? String ?? fallbackName
        let skinType = (data["skinType"] as? String) ?? (data["skinToneReference"] as? String) ?? "normal"
        let preferredLanguage = data["preferredLanguage"] as? String ?? "es"
        let notificationsEnabled = data["notificationsEnabled"] as? Bool ?? true
        let email = data["email"] as? String ?? (user.email ?? "")

        let updatedAt: Date = {
            if let timestamp = data["updatedAt"] as? Timestamp {
                return timestamp.dateValue()
            }
            if let date = data["updatedAt"] as? Date {
                return date
            }
            return Date()
        }()

        return UserProfile(
            displayName: displayName,
            skinType: skinType,
            preferredLanguage: preferredLanguage,
            notificationsEnabled: notificationsEnabled,
            email: email,
            updatedAt: updatedAt
        )
    }

    private func getDocument(_ reference: DocumentReference) async throws -> DocumentSnapshot {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DocumentSnapshot, Error>) in
            reference.getDocument { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let snapshot else {
                    continuation.resume(throwing: FirestoreUserProfileError.invalidServerResponse)
                    return
                }

                continuation.resume(returning: snapshot)
            }
        }
    }

    private func setDocument(_ reference: DocumentReference, data: [String: Any]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.setData(data, merge: true) { error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: ())
            }
        }
    }

    private func mapFirestoreError(_ error: Error) -> Error {
        let nsError = error as NSError
        if nsError.domain == FirestoreErrorDomain,
           nsError.code == FirestoreErrorCode.permissionDenied.rawValue {
            return FirestoreUserProfileError.permissionDenied
        }

        return FirestoreUserProfileError.requestFailed(message: error.localizedDescription)
    }
}