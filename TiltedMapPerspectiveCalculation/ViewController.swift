import UIKit
import GoogleMaps

final class ViewController: UIViewController {

    @IBOutlet fileprivate var map: GMSMapView!

    fileprivate var bounds: GMSCoordinateBounds?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.map.padding = UIEdgeInsets(top: 50, left: 10, bottom: 100, right: 10)
    }

    fileprivate func fitTiltedBounds(bounds: GMSCoordinateBounds, size: CGSize, angle: CLLocationDegrees,
                                     padding: UIEdgeInsets)
        -> GMSCameraPosition
    {
        let horizontalDistance = GMSGeometryDistance(bounds.southEast, bounds.southWest)
        let verticalDistance = GMSGeometryDistance(bounds.northWest, bounds.southWest)

        let boundsZoom = bounds.zoom(forSize: size, padding: padding)
        let metersPerPixel = self.meterPerPixel(at: bounds.center, zoom: boundsZoom)

        let perspective = -1 / (900.0 * (Double(size.height) / 480.0))
        let containerWidth = Double(size.width - padding.left - padding.right)
        let (scaleY, translateY) = self.valuesToFit(width: ceil(horizontalDistance / metersPerPixel),
                                                    height: ceil(verticalDistance / metersPerPixel),
                                                    withRotation: angle, perspective: perspective,
                                                    inWidth: containerWidth)

        let zoom = Float(log2(scaleY)) + boundsZoom
        let newTarget = GMSGeometryOffset(bounds.center, translateY * metersPerPixel, 0)
        return GMSCameraPosition(target: newTarget, zoom: zoom, bearing: 0, viewingAngle: angle)
    }

    private func valuesToFit(width boundsWidth: Double, height boundsHeight: Double,
                             withRotation angle: CLLocationDegrees, perspective: Double,
                             inWidth width: Double)
        -> (scaleY: Double, translateY: Double)
    {
        let angleRadians = angle * .pi / 180.0
        let sinAngle = sin(angleRadians)
        let cosAngle = cos(angleRadians)
        let tanAngle = tan(angleRadians)

        // Calculate both width and height fit scales and fit the one that is smaller
        let factorH = boundsHeight * boundsHeight * perspective * tanAngle
        let factorW = boundsHeight * perspective * sinAngle * width
        let scaleYW = 0.5 * width * (1 / boundsWidth + 1 / (boundsWidth - factorW))
        let scaleYH = 1 / (cosAngle - 0.25 * factorH * perspective * sinAngle)
        if scaleYW < scaleYH {
            return (scaleYW, (factorW * boundsHeight) / (4 * boundsWidth - 2 * factorW))
        } else {
            return (scaleYH, 0.25 * factorH)
        }
    }

    private func meterPerPixel(at position: CLLocationCoordinate2D, zoom: Float) -> Double {
        return (cos(position.latitude * .pi / 180.0) * 2 * .pi * 6378137) / (256 * pow(2, Double(zoom)))
    }
}

extension GMSCoordinateBounds {

    /// The North-West corner of these bounds.
    public var northWest: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.northEast.latitude, longitude: self.southWest.longitude)
    }

    /// The South-East corner of these bounds.
    public var southEast: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.southWest.latitude, longitude: self.northEast.longitude)
    }

    /// The center position of the bounds.
    public var center: CLLocationCoordinate2D {
        return GMSGeometryInterpolate(self.northEast, self.southWest, 0.5)
    }

    /// Minimum zoom that would fit the entire receiver for a given size in points.
    ///
    /// - parameter size: The map size in points.
    ///
    /// - returns: A double representing the zoom of the receiver bounds that fits the given size.
    public func zoom(forSize size: CGSize, padding: UIEdgeInsets) -> Float {
        let maxZoom = 21.0
        let worldDimensions = CGSize(width: 256, height: 256)

        func latitudeRadian(_ latitude: CLLocationDegrees) -> Double {
            let sinφ = sin(latitude)
            let radiansSquare = log((1 + sinφ) / (1 - sinφ)) / 2.0
            return max(min(radiansSquare, .pi), -.pi) / 2.0
        }

        func zoom(forSize points: CGFloat, worldPoints: CGFloat, fraction: Double) -> Double {
            return log(Double(points) / Double(worldPoints) / fraction) / M_LN2
        }

        let neφ = self.northEast.latitude * .pi / 180.0
        let swφ = self.southWest.latitude * .pi / 180.0

        let Δλ = self.northEast.longitude - self.southWest.longitude
        let fractionφ = (latitudeRadian(neφ) - latitudeRadian(swφ)) / .pi
        let fractionλ = (Δλ < 0 ? Δλ + 360.0 : Δλ) / 360.0

        let size = CGSize(width: size.width - padding.right - padding.left,
                          height: size.height - padding.top - padding.bottom)
        let zoomφ = zoom(forSize: size.height, worldPoints: worldDimensions.height, fraction: fractionφ)
        let zoomλ = zoom(forSize: size.width, worldPoints: worldDimensions.width, fraction: fractionλ)
        return Float(min(zoomφ, zoomλ, maxZoom))
    }
}

// MARK: - UI Stuff

extension ViewController {

    private var screenSize: CGSize {
        return CGSize(width: self.map.bounds.width - self.map.padding.left - self.map.padding.right,
                      height: self.map.bounds.height - self.map.padding.top - self.map.padding.bottom)
    }

    @IBAction private func addFullSize() {
        self.map.clear()
        self.map.moveCamera(.zoom(to: 10))

        self.addBounds(swPoint: CGPoint(x: self.map.padding.left, y: self.map.padding.top),
                       nePoint: CGPoint(x: self.screenSize.width, y: self.screenSize.height))
    }

    @IBAction private func addThin() {
        self.map.clear()
        self.map.moveCamera(.zoom(to: 10))

        self.addBounds(swPoint: CGPoint(x: 400, y: 0),
                       nePoint: CGPoint(x: self.screenSize.width, y: self.screenSize.height))
    }

    @IBAction private func addSquare() {
        self.map.clear()
        self.map.moveCamera(.zoom(to: 10))

        self.addBounds(swPoint: CGPoint(x: 0, y: 0),
                       nePoint: CGPoint(x: self.screenSize.width, y: self.screenSize.width))
    }

    @IBAction private func addAlmostFullWidth() {
        self.map.clear()
        self.map.moveCamera(.zoom(to: 10))

        self.addBounds(swPoint: CGPoint(x: 50, y: 0),
                       nePoint: CGPoint(x: self.screenSize.width, y: self.screenSize.height))
    }

    private func addBounds(swPoint: CGPoint, nePoint: CGPoint) {
        let bounds = GMSCoordinateBounds(
            coordinate: self.map.projection.coordinate(for: CGPoint(x: swPoint.x, y: swPoint.y)),
            coordinate: self.map.projection.coordinate(for: CGPoint(x: nePoint.x, y: nePoint.y))
        )

        let path = GMSMutablePath()
        path.add(bounds.northWest)
        path.add(bounds.northEast)
        path.add(bounds.southEast)
        path.add(bounds.southWest)

        let polygon = GMSPolygon(path: path)
        polygon.map = self.map
        self.map.moveCamera(.fit(bounds, with: .zero))
        self.bounds = bounds
    }

    @IBAction private func tilt() {
        guard let bounds = self.bounds else {
            return
        }

        let position = self.fitTiltedBounds(bounds: bounds, size: self.map.bounds.size, angle: 30.0,
                                            padding: self.map.padding)
        self.map.animate(with: .setCamera(position))
    }
}
