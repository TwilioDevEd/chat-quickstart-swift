//
//  ViewController.swift
//  IPMQuickstart
//
//  Created by Kevin Whinnery on 12/9/15.
//  Copyright © 2015 Twilio. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  // MARK: IP messaging memebers
  var client: TwilioIPMessagingClient? = nil
  var generalChannel: TWMChannel? = nil
  var identity = ""
  var messages: [TWMMessage] = []
  
  // MARK: UI controls
  @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var textField: UITextField!
  @IBOutlet weak var tableView: UITableView!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Fetch Access Token form the server and initialize IPM Client - this assumes you are running
    // the PHP starter app on your local machine, as instructed in the quick start guide
    let deviceId = UIDevice.currentDevice().identifierForVendor!.UUIDString
    let urlString = "http://localhost:8000/token.php?device=\(deviceId)"
    let defaultChannel = "general"
    
    // Get JSON from server
    let config = NSURLSessionConfiguration.defaultSessionConfiguration()
    let session = NSURLSession(configuration: config, delegate: nil, delegateQueue: nil)
    let url = NSURL(string: urlString)
    let request  = NSMutableURLRequest(URL: url!)
    request.HTTPMethod = "GET"
    
    // Make HTTP request
    session.dataTaskWithRequest(request, completionHandler: { data, response, error in
      if (data != nil) {
        // Parse result JSON
        let json = JSON(data: data!)
        let token = json["token"].stringValue
        self.identity = json["identity"].stringValue
        
        // Set up Twilio IPM client and join the general channel
        self.client = TwilioIPMessagingClient.ipMessagingClientWithToken(token, delegate: self)
        
        // Auto-join the general channel
        self.client?.channelsListWithCompletion { result, channels in
          if (result == .Success) {
            if let channel = channels.channelWithUniqueName(defaultChannel) {
              // Join the general channel if it already exists
              self.generalChannel = channel
              self.generalChannel?.joinWithCompletion({ result in
                print("Channel joined with result \(result)")
              })
            } else {
              // Create the general channel (for public use) if it hasn't been created yet
              channels.createChannelWithFriendlyName("General Chat Channel", type: .Public) {
                  (channelResult, channel) -> Void in
                if result == .Success {
                  self.generalChannel = channel
                  self.generalChannel?.joinWithCompletion({ result in
                    self.generalChannel?.setUniqueName(defaultChannel, completion: { result in
                      print("channel unqiue name set")
                    })
                  })
                }
              }
            }
          }
        }
        
        // Update UI on main thread
        dispatch_async(dispatch_get_main_queue()) {
          self.navigationItem.prompt = "Logged in as \"\(self.identity)\""
        }
      } else {
        print("Error fetching token :\(error)")
      }
    }).resume()
    
    // Listen for keyboard events and animate text field as necessary
    NSNotificationCenter.defaultCenter().addObserver(self,
      selector: Selector("keyboardWillShow:"),
      name:UIKeyboardWillShowNotification,
      object: nil);
    
    NSNotificationCenter.defaultCenter().addObserver(self,
      selector: Selector("keyboardDidShow:"),
      name:UIKeyboardDidShowNotification,
      object: nil);
    
    NSNotificationCenter.defaultCenter().addObserver(self,
      selector: Selector("keyboardWillHide:"),
      name:UIKeyboardWillHideNotification,
      object: nil);
    
    // Set up UI controls
    self.tableView.rowHeight = UITableViewAutomaticDimension
    self.tableView.estimatedRowHeight = 66.0
    self.tableView.separatorStyle = .None
  }
  
  // MARK: Keyboard Dodging Logic
  
  func keyboardWillShow(notification: NSNotification) {
    let keyboardHeight = notification.userInfo?[UIKeyboardFrameBeginUserInfoKey]?.CGRectValue.height
    UIView.animateWithDuration(0.1, animations: { () -> Void in
      self.bottomConstraint.constant = keyboardHeight! + 10
      self.view.layoutIfNeeded()
    })
  }
  
  func keyboardDidShow(notification: NSNotification) {
    self.scrollToBottomMessage()
  }
  
  func keyboardWillHide(notification: NSNotification) {
    UIView.animateWithDuration(0.1, animations: { () -> Void in
      self.bottomConstraint.constant = 20
      self.view.layoutIfNeeded()
    })
  }
  
  // MARK: UI Logic
  
  // Dismiss keyboard if container view is tapped
  @IBAction func viewTapped(sender: AnyObject) {
    self.textField.resignFirstResponder()
  }
  
  // Scroll to bottom of table view for messages
  func scrollToBottomMessage() {
    if self.messages.count == 0 {
      return
    }
    let bottomMessageIndex = NSIndexPath(forRow: self.tableView.numberOfRowsInSection(0) - 1,
      inSection: 0)
    self.tableView.scrollToRowAtIndexPath(bottomMessageIndex, atScrollPosition: .Bottom,
      animated: true)
  }

}

// MARK: Twilio IP Messaging Delegate
extension ViewController: TwilioIPMessagingClientDelegate {
  // Called whenever a channel we've joined receives a new message
  func ipMessagingClient(client: TwilioIPMessagingClient!, channel: TWMChannel!,
    messageAdded message: TWMMessage!) {
      self.messages.append(message)
      self.tableView.reloadData()
      dispatch_async(dispatch_get_main_queue()) {
        if self.messages.count > 0 {
          self.scrollToBottomMessage()
        }
      }
  }
}

// MARK: UITextField Delegate
extension ViewController: UITextFieldDelegate {
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    let msg = self.generalChannel?.messages.createMessageWithBody(textField.text!)
    self.generalChannel?.messages.sendMessage(msg) { result in
      textField.text = ""
      textField.resignFirstResponder()
    }
    return true
  }
}

// MARK: UITableView Delegate
extension ViewController: UITableViewDelegate {
  
  // Return number of rows in the table
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.messages.count
  }
  
  // Create table view rows
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath)
    -> UITableViewCell {
      let cell = tableView.dequeueReusableCellWithIdentifier("MessageCell", forIndexPath: indexPath)
      let message = self.messages[indexPath.row]
      
      // Set table cell values
      cell.detailTextLabel?.text = message.author
      cell.textLabel?.text = message.body
      cell.selectionStyle = .None
      return cell
  }
}

// MARK: UITableViewDataSource Delegate
extension ViewController: UITableViewDataSource {
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
}

