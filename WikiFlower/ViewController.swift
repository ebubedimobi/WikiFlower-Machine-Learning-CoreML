//
//  ViewController.swift
//  WikiFlower
//
//  Created by Ebubechukwu Dimobi on 25.07.2020.
//  Copyright © 2020 blazeapps. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {

    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var flowerDescriptionLabel: UILabel!
    
    @IBOutlet weak var otherFlowerNameLabel: UILabel!
    @IBOutlet weak var flowerNameLabel: UILabel!
    let imagePicker = UIImagePickerController()
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
     
      
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    }

    @IBAction func clearButtonPressed(_ sender: UIBarButtonItem) {
        
        flowerDescriptionLabel.text = nil
        imageView.image = nil
        otherFlowerNameLabel.text = nil
        flowerNameLabel.text = "Show Me Any Flower"
    }
    
    
    //MARK: - add image
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        let actionsheet = UIAlertController(title: "Photo Source", message: "Choose A Source", preferredStyle: .actionSheet)
        
        actionsheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action:UIAlertAction)in
            self.flowerDescriptionLabel.text = nil
            self.imageView.image = nil
            self.otherFlowerNameLabel.text = nil
            self.flowerNameLabel.text = "Show Me Any Flower"
            if UIImagePickerController.isSourceTypeAvailable(.camera){
                self.imagePicker.sourceType = .camera
                self.present(self.imagePicker, animated: true, completion: nil)
            }else
            {
                print("Camera is Not Available")
            }
        }))
        actionsheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action:UIAlertAction)in
            self.flowerDescriptionLabel.text = nil
            self.imageView.image = nil
            self.otherFlowerNameLabel.text = nil
            self.flowerNameLabel.text = "Show Me Any Flower"
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
        actionsheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionsheet,animated: true, completion: nil)
        
        present(imagePicker, animated: true)
       
        
    }
    
}
//MARK: - UIImagePicker Delegations

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{


    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        if let userPickedimage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
            
              imageView.image = userPickedimage

            guard let ciimage = CIImage(image: userPickedimage) else{
                fatalError("Could not convert to CIImage")
            }

            detect(with: ciimage)

        }

        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    

    func detect(with flowerImage: CIImage){

        do{
            let model = try VNCoreMLModel(for: FlowerClassifier().model)

            let request = VNCoreMLRequest(model: model) { (request, error) in
                guard let results = request.results as? [VNClassificationObservation] else {
                    fatalError("Could not process request")
                }

                print(results[0])
                self.flowerNameLabel.text = ("This is a \(results[0].identifier.capitalized)")
                self.requestInfo(flowerName: results[0].identifier.capitalized)

            }

            let handler = VNImageRequestHandler(ciImage: flowerImage)
            try handler.perform([request])
        }catch{
            print("error while processing image\(error)")
        }




    }
}


//MARK: - making HTTP Request

extension ViewController{
    
    
    func requestInfo(flowerName: String){
        
        let parameters : [String:String] = [
        "format" : "json",
        "action" : "query",
        "prop" : "extracts",
        "exintro" : "",
        "explaintext" : "",
        "titles" : flowerName,
        "indexpageids": "",
        "redirects" : "1",
        ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess{
                print("got flower")
                //print(response)
                
                let flowerJSON : JSON = JSON(response.result.value!)
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                let flowerTitle = flowerJSON["query"]["pages"][pageid]["title"].stringValue
                
                if flowerName != flowerTitle.capitalized {
                    self.flowerDescriptionLabel.text = (flowerDescription)
                    self.otherFlowerNameLabel.text = "Also Known as \(flowerTitle.capitalized)"
                    
                }else {
                    self.flowerDescriptionLabel.text = (flowerDescription)
                    
                }
                
                
            }
        }
        
        
    }
    
    
}
