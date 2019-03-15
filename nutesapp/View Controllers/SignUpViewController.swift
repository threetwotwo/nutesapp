//
//  SignUpViewController.swift
//  nutesapp
//
//  Created by Gary Piong on 03/01/19.
//  Copyright © 2019 Gary Piong. All rights reserved.
//

import UIKit
import FirebaseAuth

class SignUpViewController: UIViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var fullnameField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var changeSignupModeButton: UIButton!
    @IBOutlet weak var usernameMessageLabel: UILabel!
    
    //MARK: - variables
    var firestore = FirestoreManager.shared
    var isSignupMode = true
    var usernameTaken = true
    
    //MARK: - IBActions
    @IBAction func usernameFieldChanged(_ sender: UITextField) {
        guard sender.text != "" else {return}
        self.usernameMessageLabel.text = ""
    }
    
    @IBAction func signupButtonPressed(_ sender: Any) {
        
        guard usernameField.text != "",
            let email = emailField.text,
            let fullname = fullnameField.text,
            let username = usernameField.text,
            let password = passwordField.text else {return}
        
        let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainscreen") as! UITabBarController
        
        if isSignupMode {
            firestore.createUser(withEmail: email, fullname: fullname, username: username, password: password) {
                print("\(email) registered!")
                self.present(tabBarController, animated: true)
            }
        } else {
            firestore.signIn(forUsername: username, password: password) {
                print("\(username) logged in!")
                self.present(tabBarController, animated: true) 
            }
        }
        
       

        
    }
    
    @IBAction func changeSignupModeButtonPressed(_ sender: Any) {
        isSignupMode = !isSignupMode
        usernameMessageLabel.text = ""
        updateButtons()
    }
    
    fileprivate func updateUsernameMessage(using username: String) {
        
        guard isSignupMode else {return}
        
        firestore.usernameExists(username, completion: { (exists) in
            
            if exists {
                self.usernameMessageLabel.text = "username taken"
                self.signupButton.isEnabled = false
            } else {
                self.usernameMessageLabel.text  = "✓"
                self.signupButton.isEnabled = true
            }
            
        })
        
//        firestore.db.collection("usernames").document(username).getDocument { (document, error) in
//            guard error == nil,
//                let document = document else {
//                    print(error?.localizedDescription ?? "error in fetching document")
//                    return
//            }
//
//            var message = ""
//
//            if document.exists {
//                message = "username taken"
//                self.signupButton.isEnabled = false
//            } else {
//                message = "✓"
//                self.signupButton.isEnabled = true
//            }
//            self.usernameMessageLabel.text = message
//        }
    }
    
    fileprivate func updateButtons() {
        emailField.isHidden = !isSignupMode
        fullnameField.isHidden = !isSignupMode
        signupButton.isEnabled = !isSignupMode
        signupButton.setTitle(isSignupMode ? "Sign Up" : "Login", for: [])
        changeSignupModeButton.setTitle(isSignupMode ? "Already have an account?" : "Don't have an account?", for: [])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        usernameMessageLabel.text = ""
        usernameField.delegate = self
    }

}

extension SignUpViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        signupButton.isEnabled = !isSignupMode
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        guard usernameField.text != "",
            let username = usernameField.text else {return true}
        updateUsernameMessage(using: username)
        return true
    }
}
