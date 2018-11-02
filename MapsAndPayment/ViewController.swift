//
//  ViewController.swift
//  MapsAndPayment
//
//  Created by Rocky on 10/31/18.
//  Copyright © 2018 Rocky. All rights reserved.
//

import UIKit
import MapKit
import Stripe

class ViewController: UIViewController,STPPaymentContextDelegate {
   
    required init?(coder aDecoder: NSCoder) {
        customerContext = STPCustomerContext(keyProvider: APIClient.shared)
        paymentContext = STPPaymentContext(customerContext: customerContext)
        super.init(coder: aDecoder)
        paymentContext.delegate = self
        paymentContext.hostViewController = self
    }
    
    private let customerContext: STPCustomerContext
    private let paymentContext: STPPaymentContext
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let location = CLLocationCoordinate2D(latitude: 32.925499326906696,
                                              longitude: -96.95691738438146)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = "Dallas"
        annotation.subtitle = "Texas"
        mapView.addAnnotation(annotation)
        paymentContext.delegate = self

    }
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPErrorBlock) {
        let source = paymentResult.source.stripeID
        
        APIClient.shared.requestRide(source: source, amount: 77, currency: "usd") { [weak self] (ride, error) in
            guard let _ = self else {
                // View controller was deallocated
                return
            }
            
            guard error == nil else {
                // Error while requesting ride
                completion(error)
                return
            }
            

            completion(nil)
        }
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        switch status {
        case .success:
            present(UIAlertController(message: "Payment Successful"), animated: true)
        case .error:
            if let customerKeyError = error as? APIClient.CustomerKeyError {
                switch customerKeyError {
                case .missingBaseURL:
                    // Fail silently until base url string is set
                    print("[ERROR]: Please assign a value to `MainAPIClient.shared.baseURLString` before continuing. See `AppDelegate.swift`.")
                case .invalidResponse:
                    // Use customer key specific error message
                    print("[ERROR]: Missing or malformed response when attempting to `MainAPIClient.shared.createCustomerKey`. Please check internet connection and backend response formatting.");
                    
                    present(UIAlertController(message: "Could not retrieve customer information", retryHandler: { (action) in
                        // Retry payment context loading
                        paymentContext.retryLoading()
                    }), animated: true)
                }
            }
            else {
                // Use generic error message
                print("[ERROR]: Unrecognized error while loading payment context: \(String(describing: error))");
            
                present(UIAlertController(message: "Could not retrieve payment information", retryHandler: { (action) in
                    // Retry payment context loading
                    paymentContext.retryLoading()
                }), animated: true)
            }
        case .userCancellation:
            print("user cancelled")
        }
    }
    
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        
    }
    @IBAction func makePayment(_ sender: Any) {
    
        paymentContext.requestPayment()

    }
    
}


extension UIAlertController {
    
    /// Initialize an alert view titled "Oops" with `message` and single "OK" action with no handler
    convenience init(message: String?) {
        self.init(title: "Hurray!", message: message, preferredStyle: .alert)
        
        let dismissAction = UIAlertAction(title: "OK", style: .default)
        addAction(dismissAction)
        
        preferredAction = dismissAction
    }
    
    /// Initialize an alert view titled "Oops" with `message` and "Retry" / "Skip" actions
    convenience init(message: String?, retryHandler: @escaping (UIAlertAction) -> Void) {
        self.init(title: "Oops", message: message, preferredStyle: .alert)
        
        let retryAction = UIAlertAction(title: "Retry", style: .default, handler: retryHandler)
        addAction(retryAction)
        
        let skipAction = UIAlertAction(title: "Skip", style: .default)
        addAction(skipAction)
        
        preferredAction = skipAction
    }
    
}

