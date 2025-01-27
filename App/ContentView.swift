import SwiftUI

struct ContentView: View {
    @State private var showingPhotoUpload = false
    @StateObject private var photoStore = PhotoStore()
    @State private var isScanning = false
    @StateObject private var scanner = PhotoScanner()
    
    var body: some View {
        NavigationView {
            MainPageView()
                .navigationTitle("My Catch")
                .toolbar {
                    Menu {
                        Button(action: {
                            showingPhotoUpload = true
                        }) {
                            Label("Upload Photo", systemImage: "photo.badge.plus")
                        }
                        
                        Button(action: {
                            isScanning = true
                        }) {
                            Label("Import All Photos", systemImage: "square.and.arrow.down")
                        }
                    } label: {
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
        .sheet(isPresented: $isScanning) {
            NavigationView {
                ScanningView(scanner: scanner, isFirstLaunch: .constant(false))
                    .navigationTitle("Scanning Photos")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            if !scanner.isScanning {
                                Button("Done") {
                                    PhotoImportService.shared.importPhotos(
                                        from: scanner,
                                        into: photoStore
                                    )
                                    isScanning = false
                                }
                            }
                        }
                    }
            }
        }
        .environmentObject(photoStore)
    }
}
