// ClusteringMapView.swift
// UIViewRepresentable wrapper for MKMapView with clustering and annotation sync.
import SwiftUI
import MapKit
import OSLog

struct ClusteringMapView: UIViewRepresentable {

    @ObservedObject var vm: MapViewModel

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(vm.cameraRegion, animated: false)

        mapView.register(
            TempleMarkerView.self,
            forAnnotationViewWithReuseIdentifier: TempleMarkerView.reuseID
        )
        mapView.register(
            TempleClusterView.self,
            forAnnotationViewWithReuseIdentifier: TempleClusterView.reuseID
        )

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Animate to the new region if a programmatic reset was triggered
        if vm.resetRegionID != context.coordinator.lastAppliedResetID {
            context.coordinator.lastAppliedResetID = vm.resetRegionID
            mapView.setRegion(vm.cameraRegion, animated: true)
        }
        syncAnnotations(on: mapView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(vm: vm)
    }

    // MARK: - Annotation Sync

    // NOTE: syncAnnotations lives in ClusteringMapView by design — it directly
    // mutates an MKMapView instance, which is a UIKit object that must never
    // be held or mutated from the ViewModel layer.
    private func syncAnnotations(on mapView: MKMapView) {
        let existing = mapView.annotations.compactMap { $0 as? TempleAnnotation }
        let existingIDs = Set(existing.map { $0.temple.id })
        let desiredIDs  = Set(vm.visibleTemples.map { $0.id })

        let toRemove = existing.filter { !desiredIDs.contains($0.temple.id) }
        let toAdd    = vm.visibleTemples.filter { !existingIDs.contains($0.id) }

        mapView.removeAnnotations(toRemove)

        let newAnnotations = toAdd.compactMap { temple -> TempleAnnotation? in
            guard let coord = temple.coordinate else { return nil }
            let a = TempleAnnotation()
            a.temple    = temple
            a.isVisited = vm.isVisited(temple)
            a.coordinate = coord
            a.title      = temple.name
            a.subtitle   = "\(temple.location.city), \(temple.location.state)"
            return a
        }
        mapView.addAnnotations(newAnnotations)

        // Refresh visited state for already-present annotations
        for annotation in existing where desiredIDs.contains(annotation.temple.id) {
            let nowVisited = vm.isVisited(annotation.temple)
            if annotation.isVisited != nowVisited {
                annotation.isVisited = nowVisited
                if let view = mapView.view(for: annotation) as? TempleMarkerView {
                    view.markerTintColor = nowVisited
                        ? UIColor(Color.brandVisited)
                        : UIColor(Color.brandSaffron)
                }
            }
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {

        private let vm: MapViewModel
        private let logger = Logger(subsystem: "com.padyatra", category: "ClusteringMapView")
        /// Tracks the last reset we animated to, so we don't re-animate on unrelated updates.
        var lastAppliedResetID: UUID = UUID()

        init(vm: MapViewModel) {
            self.vm = vm
            self.lastAppliedResetID = vm.resetRegionID
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            switch annotation {
            case is TempleAnnotation:
                let view = mapView.dequeueReusableAnnotationView(
                    withIdentifier: TempleMarkerView.reuseID,
                    for: annotation
                ) as? TempleMarkerView
                view?.annotation = annotation
                return view

            case is MKClusterAnnotation:
                let view = mapView.dequeueReusableAnnotationView(
                    withIdentifier: TempleClusterView.reuseID,
                    for: annotation
                ) as? TempleClusterView
                view?.annotation = annotation
                return view

            default:
                return nil
            }
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? TempleAnnotation else { return }
            logger.debug("Selected temple: \(annotation.temple.id)")
            Task { @MainActor in
                self.vm.selectedTemple = annotation.temple
            }
            mapView.deselectAnnotation(annotation, animated: false)
        }

        func mapView(
            _ mapView: MKMapView,
            annotationView view: MKAnnotationView,
            calloutAccessoryControlTapped control: UIControl
        ) {
            guard let annotation = view.annotation as? TempleAnnotation else { return }
            Task { @MainActor in
                self.vm.selectedTemple = annotation.temple
            }
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            let region = mapView.region
            Task { @MainActor in
                self.vm.onRegionChange(region)
            }
        }
    }
}
