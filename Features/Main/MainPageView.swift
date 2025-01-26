import SwiftUI
import MapKit
import UIKit

/// A view that serves as the main interface for browsing and filtering photos.
/// This view provides:
/// - Monthly grouping of photos in a grid layout
/// - Toggle between grid and map view
/// - Species-based filtering
/// - Navigation to photo details
///
/// This is the primary browsing interface where users can:
/// - View photos organized by month
/// - Filter photos by species
/// - Switch between grid and map views
struct MainPageView: View {
    @EnvironmentObject var photoStore: PhotoStore
    @State private var searchText = ""
    @State private var showingMap = false
    @State private var selectedSpecies: String? = nil
    @State private var isEditing = false
    @State private var selectedPhotos: Set<UUID> = []
    @State private var showingDeleteAlert = false
    @State private var isScanning = false
    @StateObject private var scanner = PhotoScanner()
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // Get unique species from photos
    private var availableSpecies: [String] {
        let species = Set(photoStore.photos.map { $0.species })
        return species.sorted()
    }
    
    // Filter photos based on selected species
    private var filteredPhotos: [PhotoMetadata] {
        guard let selectedSpecies = selectedSpecies else {
            return photoStore.photos
        }
        return photoStore.photos.filter { $0.species == selectedSpecies }
    }
    
    // Computed property to group photos by month
    private var groupedPhotos: [(String, [PhotoMetadata])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        // First group photos by month
        let grouped = Dictionary(grouping: filteredPhotos) { photo in
            formatter.string(from: photo.timestamp)
        }
        
        // Sort photos within each group by timestamp (most recent first)
        let sortedGroups = grouped.mapValues { photos in
            photos.sorted { $0.timestamp > $1.timestamp }
        }
        
        // Sort the groups by the first photo's timestamp in each group (most recent first)
        return sortedGroups.sorted { group1, group2 in
            guard let date1 = group1.value.first?.timestamp,
                  let date2 = group2.value.first?.timestamp else {
                return false
            }
            return date1 > date2
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Picker("View", selection: $showingMap) {
                    Image(systemName: "square.grid.3x3").tag(false)
                    Image(systemName: "map").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .disabled(isEditing)
                
                Menu {
                    Button("All Species") {
                        selectedSpecies = nil
                    }
                    
                    Divider()
                    
                    ForEach(availableSpecies, id: \.self) { species in
                        Button(species) {
                            selectedSpecies = species
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedSpecies ?? "All Species")
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            .padding()
            
            if showingMap {
                MapView(photos: filteredPhotos)
            } else {
                if filteredPhotos.isEmpty {
                    ContentUnavailableView(
                        "No Photos Found",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text(selectedSpecies != nil ? "No photos found for \(selectedSpecies!)" : "No photos available")
                    )
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(groupedPhotos, id: \.0) { month, photos in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(month)
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    LazyVGrid(columns: columns, spacing: 2) {
                                        ForEach(photos) { metadata in
                                            if isEditing {
                                                PhotoThumbnail(metadata: metadata)
                                                    .overlay(selectionOverlay(for: metadata))
                                                    .onTapGesture {
                                                        handlePhotoTap(metadata)
                                                    }
                                            } else {
                                                NavigationLink(destination: PhotoDetailView(photo: metadata)) {
                                                    PhotoThumbnail(metadata: metadata)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
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
                } else {
                    Menu {
                        Button(action: {
                            isScanning = true
                        }) {
                            Label("Import All Fish Photos", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
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
        .alert("Delete Photos?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteSelectedPhotos()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(selectedPhotos.count) photo\(selectedPhotos.count == 1 ? "" : "s")?")
        }
        .onAppear {
            _ = photoStore.loadMetadata()
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
        }
    }
    
    private func deleteSelectedPhotos() {
        for id in selectedPhotos {
            photoStore.deletePhoto(withId: id)
        }
        selectedPhotos.removeAll()
        isEditing = false
    }
}
