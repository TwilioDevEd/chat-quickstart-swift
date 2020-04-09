//
//  ChatViewController.swift
//  Twilio Starter App
//
//  Created by Jeffrey Linwood, Kevin Whinnery on 11/29/16.
//  Copyright © 2016 Twilio, Inc. All rights reserved.
//

import UIKit

import TwilioChatClient

class ChatViewController: UIViewController {

    // Important - this identity would be assigned by your app, for
    // instance after a user logs in
    var identity = "USER_IDENTITY"

    // Convenience class to manage interactions with Twilio Chat
    var chatManager = QuickstartChatManager()

    // MARK: UI controls
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        chatManager.delegate = self

        // Listen for keyboard events and animate text field as necessary
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidShow),
                                               name: UIResponder.keyboardDidShowNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)

        // Set up UI controls
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 66.0
        self.tableView.separatorStyle = .none
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        login()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        chatManager.shutdown()
    }

    // MARK: Login / Logout

    func login() {
        chatManager.login(self.identity) { (success) in
            DispatchQueue.main.async() {
                if success {
                    self.navigationItem.prompt = "Logged in as \"\(self.identity)\""
                } else {
                    self.navigationItem.prompt = "Unable to login"
                    let msg = "Unable to login - check the token URL in ChatConstants.swift"
                    self.displayErrorMessage(msg)
                }
            }
        }
    }

    // MARK: Keyboard Dodging Logic

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey]
            as? NSValue)?.cgRectValue {
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.bottomConstraint.constant = keyboardRect.height + 10
                self.view.layoutIfNeeded()
            })
        }
    }

    @objc func keyboardDidShow(notification: NSNotification) {
        scrollToBottomMessage()
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.bottomConstraint.constant = 20
            self.view.layoutIfNeeded()
        })
    }

    // MARK: UI Logic

    // Dismiss keyboard if container view is tapped
    @IBAction func viewTapped(_ sender: Any) {
        self.textField.resignFirstResponder()
    }

    private func scrollToBottomMessage() {
        if chatManager.messages.count == 0 {
            return
        }
        let bottomMessageIndex = IndexPath(row: chatManager.messages.count - 1,
                                           section: 0)
        tableView.scrollToRow(at: bottomMessageIndex, at: .bottom, animated: true)
    }

    private func displayErrorMessage(_ errorMessage: String) {
        let alertController = UIAlertController(title: "Error",
                                                message: errorMessage,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: UITextField Delegate
extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        chatManager.sendMessage(textField.text!, completion: { (result, message) in
            textField.text = ""
            textField.resignFirstResponder()
        })
        return true
    }
}

// MARK: UITableViewDataSource Delegate
extension ChatViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // Return number of rows in the table
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return chatManager.messages.count
    }

    // Create table view rows
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell",
                                                     for: indexPath)
            let message = chatManager.messages[indexPath.row]

            // Set table cell values
            cell.detailTextLabel?.text = message.author
            cell.textLabel?.text = message.body
            cell.selectionStyle = .none
            return cell
    }
}

// MARK: QuickstartChatManagerDelegate
extension ChatViewController: QuickstartChatManagerDelegate {
    func reloadMessages() {
        self.tableView.reloadData()
    }

    // Scroll to bottom of table view for messages
    func receivedNewMessage() {
        scrollToBottomMessage()
    }
}
