import SwiftUI

struct ContentView: View {
    @State private var showingPhotoUpload = false
    @StateObject private var photoStore = PhotoStore()
    
    var body: some View {
        NavigationView {
            MainPageView()
                .navigationTitle("My Fish")
                .toolbar {
                    Button(action: {
                        showingPhotoUpload = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
        }
        .sheet(isPresented: $showingPhotoUpload) {
            NavigationView {
                PhotoUploadView()
                    .navigationTitle("Add Fish Photo")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        Button("Cancel") {
                            showingPhotoUpload = false
                        }
                    }
            }
            .environmentObject(photoStore)
        }
        .environmentObject(photoStore)
    }
}
