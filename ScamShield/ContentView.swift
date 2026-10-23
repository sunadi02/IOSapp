//
//  ContentView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-21.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        VStack {
            Image(systemName: "shield.lefthalf.filled")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("ScamShield")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
