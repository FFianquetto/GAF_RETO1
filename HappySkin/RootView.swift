//
//  RootView.swift
//  HappySkin
//

import SwiftUI

struct RootView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if authViewModel.user == nil {
                AuthView()
            } else {
                MainScreenView()
            }
        }
        .environmentObject(authViewModel)
        .animation(.easeInOut, value: authViewModel.user != nil)
    }
}

#Preview {
    RootView()
}
