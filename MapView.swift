import SwiftUI
import MapKit
import CoreLocation

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
                        .navigationBarItems(trailing: Button("Done") {
                            showingPhotoDetail = false
                            selectedPhoto = nil
                        })
                }
            }
        }
        .onAppear {
            setInitialRegion()
        }
    }
    
    private func setInitialRegion() {
        guard !photosWithCoordinates.isEmpty else { return }
        
        let coordinates = photosWithCoordinates.compactMap { photo -> CLLocationCoordinate2D? in
            guard let lat = photo.latitude,
                  let lon = photo.longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        
        guard !coordinates.isEmpty else { return }
        
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        
        region = MKCoordinateRegion(center: center, span: span)
    }
    
    private func zoomIn() {
        region.span = MKCoordinateSpan(
            latitudeDelta: region.span.latitudeDelta * 0.5,
            longitudeDelta: region.span.longitudeDelta * 0.5
        )
    }
    
    private func zoomOut() {
        region.span = MKCoordinateSpan(
            latitudeDelta: region.span.latitudeDelta * 2,
            longitudeDelta: region.span.longitudeDelta * 2
        )
    }
} 
