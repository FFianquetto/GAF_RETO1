//
//  LoadingView.swift
//  HappySkin
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color(red: 11 / 255, green: 15 / 255, blue: 20 / 255))
                .ignoresSafeArea()

            logoImage
                .frame(width: 259, height: 275)
        }
    }

    private var logoImage: some View {
        Image("Logo")
            .resizable()
            .scaledToFit()
    }
}

#Preview {
    LoadingView()
}
