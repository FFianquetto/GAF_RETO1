//
//  RootView.swift
//  HappySkin
//

import SwiftUI

struct RootView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var isShowingLoading = true

    var body: some View {
        Group {
            if isShowingLoading {
                LoadingView()
            } else {
                if authViewModel.user == nil {
                    AuthView()
                } else {
                    MainScreenView()
                }
            }
        }
        .environmentObject(authViewModel)
        .animation(.easeInOut, value: isShowingLoading)
        .animation(.easeInOut, value: authViewModel.user != nil)
        .task {
            guard isShowingLoading else { return }
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            isShowingLoading = false
        }
    }
}

#Preview {
    RootView()
}
