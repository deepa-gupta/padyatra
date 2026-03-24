// TempleMapAnnotation.swift
// MKAnnotation + MKAnnotationView subclasses for temple map pins.
// TempleAnnotation carries the temple model. TempleMarkerView handles visual state.
import MapKit
import SwiftUI
import UIKit

// MARK: - TempleAnnotation

/// MKPointAnnotation subclass that carries the full Temple model.
final class TempleAnnotation: MKPointAnnotation {
    var temple: Temple!
    var isVisited: Bool = false
}

// MARK: - TempleMarkerView

/// Marker view with clustering support.
/// Visited temples use brandVisited green; unvisited use brandSaffron orange.
final class TempleMarkerView: MKMarkerAnnotationView {

    // MARK: - Constants

    static let reuseID = "TempleMarkerView"

    // MARK: - Init

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "temple"
        canShowCallout = true
        rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        clusteringIdentifier = "temple"
        canShowCallout = true
        rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        configure()
    }

    // MARK: - Layout

    override func prepareForReuse() {
        super.prepareForReuse()
        configure()
    }

    override var annotation: MKAnnotation? {
        didSet { configure() }
    }

    // MARK: - Private

    private func configure() {
        guard let templeAnnotation = annotation as? TempleAnnotation else {
            glyphText = nil
            glyphImage = UIImage(systemName: "building.columns")
            markerTintColor = UIColor(Color.brandTempleGrey)
            return
        }

        glyphImage = nil
        glyphText = "ॐ"

        if templeAnnotation.isVisited {
            markerTintColor = UIColor(Color.brandVisited)
        } else {
            markerTintColor = UIColor(Color.brandSaffron)
        }

        displayPriority = templeAnnotation.isVisited ? .defaultHigh : .defaultLow
    }
}

// MARK: - ClusterAnnotationView

/// Cluster view that summarises N temple annotations into a single pin.
final class TempleClusterView: MKAnnotationView {

    static let reuseID = "TempleClusterView"

    private let countLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    override var annotation: MKAnnotation? {
        didSet { updateCount() }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        updateCount()
    }

    private func setupView() {
        let size: CGFloat = 40
        frame = CGRect(x: 0, y: 0, width: size, height: size)

        let circle = UIView(frame: bounds)
        circle.backgroundColor = UIColor(Color.brandDeepOrange)
        circle.layer.cornerRadius = size / 2
        circle.layer.borderColor = UIColor.white.cgColor
        circle.layer.borderWidth = 2
        addSubview(circle)
        addSubview(countLabel)

        NSLayoutConstraint.activate([
            countLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func updateCount() {
        guard let cluster = annotation as? MKClusterAnnotation else { return }
        countLabel.text = "\(cluster.memberAnnotations.count)"
    }
}
