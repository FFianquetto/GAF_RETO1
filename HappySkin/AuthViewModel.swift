//
//  AuthViewModel.swift
//  HappySkin
//

import Foundation
import FirebaseAuth
import FirebaseCore
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
#if canImport(FacebookCore)
import FacebookCore
#endif
#if canImport(FacebookLogin)
import FacebookLogin
#endif
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var profile: UserProfile?
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private let profileStore = FirestoreUserProfileStore.shared
#if canImport(FacebookLogin)
    private let facebookLoginManager = LoginManager()
#endif

    init() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }

            Task { @MainActor in
                self.user = user

                guard let user else {
                    self.profile = nil
                    return
                }

                await self.loadOrCreateProfile(for: user)
            }
        }
    }

    deinit {
        if let authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(authStateListenerHandle)
        }
    }

    func signInWithEmail() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Captura correo y contraseña."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUpWithEmail() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Captura correo y contraseña."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await Auth.auth().createUser(withEmail: email, password: password)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signInWithGoogle() async {
#if canImport(GoogleSignIn) && canImport(UIKit)
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "No se encontró clientID en Firebase."
            return
        }

        guard let rootViewController = Self.rootViewController() else {
            errorMessage = "No se encontró una pantalla para presentar Google Sign-In."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let configuration = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = configuration

            let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = signInResult.user.idToken?.tokenString else {
                errorMessage = "No se pudo obtener el token de Google."
                return
            }

            let accessToken = signInResult.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            _ = try await Auth.auth().signIn(with: credential)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
#else
        errorMessage = "Google Sign-In no está disponible para esta plataforma."
#endif
    }

    func signInWithFacebook() async {
#if canImport(FacebookLogin) && canImport(FacebookCore) && canImport(UIKit)
        guard let rootViewController = Self.rootViewController() else {
            errorMessage = "No se encontró una pantalla para presentar Facebook Login."
            return
        }

        isLoading = true
        defer { isLoading = false }

        await withCheckedContinuation { continuation in
            facebookLoginManager.logIn(permissions: ["public_profile", "email"], from: rootViewController) { [weak self] result, error in
                guard let self else {
                    continuation.resume()
                    return
                }

                if let error {
                    self.errorMessage = error.localizedDescription
                    continuation.resume()
                    return
                }

                if let result, result.isCancelled {
                    self.errorMessage = "Inicio de sesión con Facebook cancelado."
                    continuation.resume()
                    return
                }

                guard let accessToken = AccessToken.current?.tokenString else {
                    self.errorMessage = "No se pudo obtener el token de Facebook."
                    continuation.resume()
                    return
                }

                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken)

                Task { @MainActor in
                    do {
                        _ = try await Auth.auth().signIn(with: credential)
                        self.errorMessage = nil
                    } catch {
                        self.errorMessage = error.localizedDescription
                    }
                    continuation.resume()
                }
            }
        }
#else
        errorMessage = "Facebook Login no está disponible para esta plataforma."
#endif
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            profile = nil
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveProfile(_ profile: UserProfile) async throws {
        guard let user else {
            throw NSError(domain: "AuthViewModel", code: 401, userInfo: [NSLocalizedDescriptionKey: "No hay una sesion activa."])
        }

        try await profileStore.saveProfile(profile, for: user)
        self.profile = profile
        errorMessage = nil
    }

    private func loadOrCreateProfile(for user: User) async {
        let fallbackName = user.email?.components(separatedBy: "@").first ?? "Usuario"

        do {
            let loadedProfile = try await profileStore.fetchOrCreateProfile(for: user, fallbackName: fallbackName)
            profile = loadedProfile
        } catch {
            profile = UserProfile.defaults(email: user.email ?? "", fallbackName: fallbackName)
            errorMessage = "No se pudo sincronizar el perfil con Firestore: \(error.localizedDescription)"
        }
    }

#if canImport(UIKit)
    private static func rootViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        for scene in scenes {
            if let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                return root
            }
        }

        return scenes.first?.windows.first?.rootViewController
    }
#endif
}
