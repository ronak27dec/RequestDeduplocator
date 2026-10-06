//
//  ContentView.swift
//  RequestDeduplocator
//
//  Created by Ronak Malick on 01/02/26.
//

import SwiftUI

struct ContentView: View {
    let singleFlight = SingleFlight()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            
            Button("Click Me!") {
                onSubmitTapped()
            }
        }
        .padding()
    }
    
    func onSubmitTapped() {
        Task {
            await singleFlight.run {
                await submit()
            }
        }
    }
    
    func submit() async -> Void {
        print("Submit clicked")
    }
}

#Preview {
    ContentView()
}
