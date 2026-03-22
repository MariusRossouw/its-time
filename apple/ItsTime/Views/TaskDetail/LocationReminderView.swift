import SwiftUI
import MapKit
import CoreLocation

struct LocationReminderView: View {
    @Bindable var task: TaskItem

    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Form {
            if task.hasLocationReminder {
                // Current location reminder
                Section("Location") {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.red)
                        VStack(alignment: .leading) {
                            Text(task.locationName ?? "Selected Location")
                                .font(.subheadline)
                            if let lat = task.locationLatitude, let lon = task.locationLongitude {
                                Text(String(format: "%.4f, %.4f", lat, lon))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    mapPreview
                }

                Section("Trigger") {
                    Picker("Remind me", selection: Binding(
                        get: { task.locationDirection },
                        set: {
                            task.locationDirection = $0
                            task.updatedAt = Date()
                            LocationTriggerService.shared.stopMonitoringTask(task)
                            LocationTriggerService.shared.startMonitoringTask(task)
                        }
                    )) {
                        ForEach(LocationReminderDirection.allCases, id: \.self) { dir in
                            Label(dir.label, systemImage: dir.icon).tag(dir)
                        }
                    }

                    HStack {
                        Text("Radius")
                        Spacer()
                        Text("\(Int(task.locationRadius))m")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $task.locationRadius, in: 50...1000, step: 50) {
                        Text("Radius")
                    }
                    .onChange(of: task.locationRadius) {
                        task.updatedAt = Date()
                        LocationTriggerService.shared.stopMonitoringTask(task)
                        LocationTriggerService.shared.startMonitoringTask(task)
                    }
                }

                Section {
                    Button("Remove Location Reminder", role: .destructive) {
                        LocationTriggerService.shared.stopMonitoringTask(task)
                        task.locationLatitude = nil
                        task.locationLongitude = nil
                        task.locationName = nil
                        task.locationDirectionRaw = nil
                        task.locationRadius = 200.0
                        task.updatedAt = Date()
                    }
                }
            } else {
                // Search for a place
                Section("Search Location") {
                    TextField("Search for a place...", text: $searchText)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .onSubmit { searchLocation() }

                    if !searchResults.isEmpty {
                        ForEach(searchResults, id: \.self) { item in
                            Button {
                                selectLocation(item)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name ?? "Unknown")
                                        .font(.subheadline)
                                    if let address = item.placemark.title {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        useCurrentLocation()
                    } label: {
                        Label("Use Current Location", systemImage: "location.fill")
                    }
                }
            }
        }
        .navigationTitle("Location Reminder")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    @ViewBuilder
    private var mapPreview: some View {
        if let lat = task.locationLatitude, let lon = task.locationLongitude {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            Map(position: .constant(.region(MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: task.locationRadius * 3,
                longitudinalMeters: task.locationRadius * 3
            )))) {
                MapCircle(center: coordinate, radius: task.locationRadius)
                    .foregroundStyle(.blue.opacity(0.15))
                    .stroke(.blue, lineWidth: 1)
                Annotation(task.locationName ?? "", coordinate: coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
    }

    private func searchLocation() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText

        if let loc = LocationTriggerService.shared.currentLocation {
            request.region = MKCoordinateRegion(
                center: loc,
                latitudinalMeters: 50000,
                longitudinalMeters: 50000
            )
        }

        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            searchResults = response?.mapItems ?? []
        }
    }

    private func selectLocation(_ item: MKMapItem) {
        let coord = item.placemark.coordinate
        task.locationLatitude = coord.latitude
        task.locationLongitude = coord.longitude
        task.locationName = item.name
        task.locationDirection = .arrive
        task.updatedAt = Date()
        searchResults = []
        searchText = ""

        LocationTriggerService.shared.startMonitoringTask(task)
    }

    private func useCurrentLocation() {
        guard let loc = LocationTriggerService.shared.currentLocation else {
            LocationTriggerService.shared.requestCurrentLocation()
            return
        }

        task.locationLatitude = loc.latitude
        task.locationLongitude = loc.longitude
        task.locationName = "Current Location"
        task.locationDirection = .leave
        task.updatedAt = Date()

        LocationTriggerService.shared.startMonitoringTask(task)
    }
}
