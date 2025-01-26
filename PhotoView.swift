import SwiftUI
import Foundation

struct PhotoView: View {
    @EnvironmentObject var photoStore: PhotoStore
    @State private var selectedPhotos: Set<UUID> = []
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 20) {
                    ForEach(photoStore.photos) { photo in
                        if isEditing {
                            // Selection mode
                            PhotoCard(photo: photo)
                                .overlay(selectionOverlay(for: photo))
                                .onTapGesture {
                                    handlePhotoTap(photo)
                                }
                        } else {
                            // Navigation mode
                            NavigationLink(destination: PhotoDetailView(photo: photo)) {
                                PhotoCard(photo: photo)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Photos")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditing ? "Cancel" : "Select") {
                        withAnimation {
                            isEditing.toggle()
                            if !isEditing {
                                selectedPhotos.removeAll()
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Delete", role: .destructive) {
                            showingDeleteAlert = true
                        }
                        .disabled(selectedPhotos.isEmpty)
                    }
                }
            }
            .alert("Delete Photos?", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteSelectedPhotos()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete \(selectedPhotos.count) photo\(selectedPhotos.count == 1 ? "" : "s")?")
            }
        }
    }
    
    private func selectionOverlay(for photo: PhotoMetadata) -> some View {
        ZStack {
            if isEditing {
                Color.black.opacity(0.3)
                
                Image(systemName: selectedPhotos.contains(photo.id) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(selectedPhotos.contains(photo.id) ? .blue : .white)
                    .padding(8)
            }
        }
    }
    
    private func handlePhotoTap(_ photo: PhotoMetadata) {
        if isEditing {
            withAnimation {
                if selectedPhotos.contains(photo.id) {
                    selectedPhotos.remove(photo.id)
                } else {
                    selectedPhotos.insert(photo.id)
                }
            }
            print("\n=== 📸 Photo Selection ===")
            print("Selected photos count: \(selectedPhotos.count)")
            print("==================\n")
        }
    }
    
    private func deleteSelectedPhotos() {
        print("\n=== 🗑️ Deleting Selected Photos ===")
        print("Number of photos to delete: \(selectedPhotos.count)")
        
        for id in selectedPhotos {
            photoStore.deletePhoto(withId: id)
        }
        
        selectedPhotos.removeAll()
        isEditing = false
        
        print("✅ Deletion complete")
        print("==================\n")
    }
}

struct PhotoGridView: View {
    let photos: [PhotoMetadata]
    @Binding var selectedPhotos: Set<UUID>
    let isEditing: Bool
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 20) {
                ForEach(photos) { photo in
                    PhotoCardView(
                        photo: photo,
                        isSelected: selectedPhotos.contains(photo.id),
                        isEditing: isEditing
                    )
                    .onTapGesture {
                        handleTap(photo: photo)
                    }
                }
            }
            .padding()
        }
    }
    
    private func handleTap(photo: PhotoMetadata) {
        if isEditing {
            if selectedPhotos.contains(photo.id) {
                selectedPhotos.remove(photo.id)
            } else {
                selectedPhotos.insert(photo.id)
            }
        }
    }
}

struct PhotoCardView: View {
    let photo: PhotoMetadata
    let isSelected: Bool
    let isEditing: Bool
    
    var body: some View {
        PhotoCard(photo: photo)
            .overlay(
                ZStack {
                    if isEditing {
                        Color.black.opacity(0.3)
                        
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24))
                            .foregroundColor(isSelected ? .blue : .white)
                            .padding(8)
                    }
                }
            )
    }
}
