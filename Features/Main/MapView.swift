import SwiftUI
import MapKit
import CoreLocation
//import Models // For PhotoMetadata

struct MapView: View {
    let photos: [PhotoMetadata]
    @State private var selectedPhoto: PhotoMetadata?
    @State private var showingPhotoDetail = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 180)
    )
    
    var photosWithCoordinates: [PhotoMetadata] {
        photos.filter { $0.latitude != nil && $0.longitude != nil }
    }
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, annotationItems: photosWithCoordinates) { photo in
                MapAnnotation(
                    coordinate: CLLocationCoordinate2D(
                        latitude: photo.latitude ?? 0,
                        longitude: photo.longitude ?? 0
                    )
                ) {
                    Image(systemName: "fish.fill")
                        .foregroundColor(.blue)
                        .background(Circle()
                            .fill(.white)
                            .frame(width: 30, height: 30))
                        .onTapGesture {
                            selectedPhoto = photo
                            showingPhotoDetail = true
                        }
                }
            }
            .mapStyle(.standard)
            .mapControls {
                MapCompass()
                MapScaleView()
                MapUserLocationButton()
            }
            
            // Zoom controls
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Button(action: {
                            withAnimation {
                                zoomIn()
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            withAnimation {
                                zoomOut()
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingPhotoDetail) {
            if let photo = selectedPhoto {
                NavigationView {
                    PhotoDetailView(photo: photo)
                }
            }
        }
    }
    
    private func zoomIn() {
        region.span = MKCoordinateSpan(
            latitudeDelta: region.span.latitudeDelta / 2,
            longitudeDelta: region.span.longitudeDelta / 2
        )
    }
    
    private func zoomOut() {
        region.span = MKCoordinateSpan(
            latitudeDelta: min(region.span.latitudeDelta * 2, 180),
            longitudeDelta: min(region.span.longitudeDelta * 2, 180)
        )
    }
} 

