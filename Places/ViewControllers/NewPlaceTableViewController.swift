//
//  NewPlaceTableViewController.swift
//  Places
//
//  Created by Ilya Pavlov on 22.07.2023.
//

import UIKit
import PhotosUI

class NewPlaceTableViewController: UITableViewController {
    
    var currentPlace: Place!
    var imageIsChanged = false
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var imageOfPlace: UIImageView!
    @IBOutlet weak var nameOfPlace: UITextField!
    @IBOutlet weak var locationOfPlace: UITextField!
    @IBOutlet weak var typeOfPlace: UITextField!
    @IBOutlet weak var ratingControl: RatingControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Новое место"
        
        saveButton.isEnabled = false
        
        nameOfPlace.addTarget(self, action: #selector(updateSaveButtonState), for: .editingChanged)
        
        setUpEditScreen()
        
    }
    
    // MARK: - Table View delegate
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            let cameraIcon = UIImage(systemName: "camera")
            let photoIcon = UIImage(systemName: "photo")
            
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let camera = UIAlertAction(title: "Camera", style: .default) { _ in
                self.chooseImagePicker(source: .camera)
            }
            camera.setValue(cameraIcon, forKey: "image")
            camera.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            
            let photo = UIAlertAction(title: "Photo", style: .default) { _ in
                self.chooseImagePicker(source: .photoLibrary)
            }
            photo.setValue(photoIcon, forKey: "image")
            photo.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            
            actionSheet.addAction(camera)
            actionSheet.addAction(photo)
            actionSheet.addAction(cancel)
            
            present(actionSheet, animated: true)
            
        } else {
            view.endEditing(true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier, let mapVC = segue.destination as? MapViewController else { return }
        
        mapVC.incomeSegueIdentifier = identifier
        if identifier == "showPlace" {
            mapVC.place.name = nameOfPlace.text!
            mapVC.place.location = locationOfPlace.text
            mapVC.place.type = typeOfPlace.text
            mapVC.place.imageData = imageOfPlace.image?.pngData()
        }
        
        mapVC.mapViewContorllerDelegate = self
    }
    
    func savePlace() {
        let config = UIImage.SymbolConfiguration(hierarchicalColor: .darkGray)
        let image = imageIsChanged ? imageOfPlace.image : UIImage(systemName: "fork.knife.circle", withConfiguration: config)
        let imageData = image?.pngData()
        let newPlace = Place(name: nameOfPlace.text!, location: locationOfPlace.text, type: typeOfPlace.text, imageData: imageData, rating: Double(ratingControl.rating))
        
        if currentPlace != nil {
            try! realm.write {
                currentPlace?.name = newPlace.name
                currentPlace?.location = newPlace.location
                currentPlace?.type = newPlace.type
                currentPlace?.imageData = newPlace.imageData
                currentPlace?.rating = newPlace.rating
            }
        } else {
            StorageManager.saveObject(newPlace)
        }
    }
    
    private func setUpEditScreen() {
        if currentPlace != nil {
            imageIsChanged = true
            guard let data = currentPlace?.imageData, let image = UIImage(data: data) else {return}
            
            imageOfPlace.image = image
            imageOfPlace.contentMode = .scaleAspectFill
            nameOfPlace.text = currentPlace?.name
            locationOfPlace.text = currentPlace?.location
            typeOfPlace.text = currentPlace?.type
            ratingControl.rating = Int(currentPlace.rating)
            
            title = currentPlace?.name
            saveButton.isEnabled = true
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
}

// MARK: - Text field delegate

extension NewPlaceTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc private func updateSaveButtonState() {
        if nameOfPlace.text?.isEmpty == false {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }
}

// MARK: - Work with image
extension NewPlaceTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func chooseImagePicker(source: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = source
        
        imageIsChanged = true
        
        present(imagePicker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        imageOfPlace.image = info[.editedImage] as? UIImage
        
        imageOfPlace.contentMode = .scaleAspectFill
        imageOfPlace.clipsToBounds = true
        dismiss(animated: true)
    }
}

extension NewPlaceTableViewController: MapViewControllerDelegate {
    func getAddress(_ address: String?) {
        locationOfPlace.text = address
    }
}
