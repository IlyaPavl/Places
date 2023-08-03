//
//  MapViewController.swift
//  Pods
//
//  Created by Ilya Pavlov on 03.08.2023.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    var place: Place!
    
    @IBOutlet weak var mavView: MKMapView!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func closeMapVc() {
        dismiss(animated: true)
    }
    
}
