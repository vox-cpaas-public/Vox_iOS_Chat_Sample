//
//  LocationViewController.swift
//  ChatSample
//
//  Created by Murali Sai Tummala on 08/05/19.
//  Copyright © 2019 Voxvalley technologies. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit


protocol LocationViewControllerDelegate: NSObjectProtocol {
    func locationViewController(_ picker: LocationViewController?, didFinishPickingLocation location: CLLocationCoordinate2D)
    func locationViewControllerDidCancel(_ picker: LocationViewController?)
}

class LocationViewController: UIViewController,CLLocationManagerDelegate,MKMapViewDelegate {
    
    static let VIEW_MODE_MAP: Int = 0
    static let VIEW_MODE_HYBRID: Int = 1
    
    var delegate: LocationViewControllerDelegate?
    
    var locationManager: CLLocationManager!
    @IBOutlet weak var mapView: MKMapView!
    var currentLocation: CLLocationCoordinate2D!
    var locationMarker: MKPointAnnotation!
    
    
    @IBAction func sendButtonAction(_ sender: UIBarButtonItem) {
        locationMarker = MKPointAnnotation()
        locationMarker.coordinate = currentLocation
        self.delegate?.locationViewController(self, didFinishPickingLocation: locationMarker.coordinate)
        
    }
    
    
    @IBAction func cancelButtonAction(_ sender: UIBarButtonItem) {
        
        self.delegate?.locationViewControllerDidCancel(self)
        
    }
    
    @IBAction func mapTypeAction(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == LocationViewController.VIEW_MODE_MAP {
            mapView?.mapType = .standard
        } else {
            mapView?.mapType = .hybrid
        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        currentLocation = CLLocationCoordinate2D()
        
        if CLLocationManager .locationServicesEnabled() {
            
            switch CLLocationManager.authorizationStatus(){
                
            case .notDetermined:
                locationManager.requestAlwaysAuthorization()
                break
            case .restricted:
                break
            case .denied:
                let alert = UIAlertController(title: "Access to location services is denied", message: "Please change settings in Privacy -> Location Services", preferredStyle: .alert)
                let settingsButton = UIAlertAction(title: "Settings", style: .default, handler: { action in
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                })
                alert.addAction(settingsButton)
                
                let okButton = UIAlertAction(title: "Ok", style: .cancel, handler: { action in
                    
                })
                
                alert.addAction(okButton)
                present(alert, animated: true)
                break
            case .authorizedAlways: break
            case .authorizedWhenInUse: break
            default:
                break
            }
            
        }
        
    }
    
    // MARK:  ----- mapKit delegate methods......
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else {return}
        currentLocation.latitude = newLocation.coordinate.latitude
        currentLocation.longitude = newLocation.coordinate.longitude
        if locationManager == nil {
            locationMarker = MKPointAnnotation()
            locationMarker.coordinate = currentLocation
            mapView.addAnnotation(locationMarker)
        }
        
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let annotaionIdentifier = "annotationIdentifier"
        var aView = mapView.dequeueReusableAnnotationView(withIdentifier: annotaionIdentifier) as? MKPinAnnotationView
        if aView == nil {
            
            aView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotaionIdentifier)
            aView?.pinTintColor = .green
            aView?.animatesDrop = true
            aView?.isDraggable = true
        }
        return aView
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == .authorizedAlways || status == .authorizedAlways || status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            mapView.isZoomEnabled = true
            mapView.userTrackingMode = .follow
        }
        else if status == .denied{
            
            let alert = UIAlertController(title: "Access to location services is denied", message: "Please change settings in Privacy -> Location Services", preferredStyle: .alert)
            let settingsButton = UIAlertAction(title: "Settings", style: .default, handler: { action in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            })
            alert.addAction(settingsButton)
            
            let okButton = UIAlertAction(title: "Ok", style: .cancel, handler: { action in
                
            })
            
            alert.addAction(okButton)
            present(alert, animated: true)
        }
    }
    
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
