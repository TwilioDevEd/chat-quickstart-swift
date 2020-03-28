//
//  QuickstartChatManager.swift
//  ChatQuickstart
//
//  Created by Jeffrey Linwood on 3/11/20.
//  Copyright © 2020 Twilio, Inc. All rights reserved.
//

import UIKit

import TwilioChatClient

protocol QuickstartChatManagerDelegate {
    func reloadMessages()
    func scrollToBottomMessage()
}

class QuickstartChatManager:NSObject, TwilioChatClientDelegate {
    
    // Important - update this URL with your Twilio Function URL
    // Important - this function must be protected in production
    // and actually check if user could be granted access to your chat service.
    let tokenURL = "https://YOUR_TWILIO_FUNCTION_DOMAIN_HERE.twil.io/chat-token"
    
    var chatManagerDelegate: QuickstartChatManagerDelegate?
    
    // MARK: Chat variables
    var client: TwilioChatClient? = nil
    var generalChannel: TCHChannel? = nil
    var messages: [TCHMessage] = []
    
    func chatClient(_ client: TwilioChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
        if status == .completed {
            // Join (or create) the general channel
            let defaultChannel = "general"
            if let channelsList = client.channelsList() {
                channelsList.channel(withSidOrUniqueName: defaultChannel, completion: { (result, channel) in
                    if let channel = channel {
                        self.generalChannel = channel
                        channel.join(completion: { result in
                            print("Channel joined with result \(result)")
                            
                        })
                    } else {
                        // Create the general channel (for public use) if it hasn't been created yet
                        channelsList.createChannel(options: [TCHChannelOptionFriendlyName: "General Chat Channel", TCHChannelOptionType: TCHChannelType.public.rawValue], completion: { (result, channel) -> Void in
                                if result.isSuccessful() {
                                    self.generalChannel = channel
                                    self.generalChannel?.join(completion: { result in
                                        self.generalChannel?.setUniqueName(defaultChannel, completion: { result in
                                            print("channel unique name set")
                                        })
                                    })
                                }
                        })
                    }
                })
            }
        }
    }
    
    // Called whenever a channel we've joined receives a new message
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel,
                    messageAdded message: TCHMessage) {
        self.messages.append(message)

        DispatchQueue.main.async() {
            if let delegate = self.chatManagerDelegate {
                delegate.reloadMessages()
                if self.messages.count > 0 {
                    delegate.scrollToBottomMessage()
                }
            }
        }
    }
    
    func getMessages() -> [TCHMessage] {
        return messages
    }
    
    func sendMessage(_ messageText:String, completion: @escaping (TCHResult, TCHMessage?) -> Void) {
        if let messages = self.generalChannel?.messages {
            let messageOptions = TCHMessageOptions().withBody(messageText)
            messages.sendMessage(with: messageOptions, completion: { (result, message) in
                completion(result, message)
            })
        }
    }
    
    
    func login(_ identity:String, completion:@escaping (TCHResult)->Void) {
        // Fetch Access Token from the server and initialize Chat Client - this assumes you are
        // calling a Twilio function, as described in the Quickstart docs
        let urlString = "\(tokenURL)?identity=\(identity)"
        
        TokenUtils.retrieveToken(url: urlString) { (token, identity, error) in
            if let token = token {
                // Set up Twilio Chat client
                TwilioChatClient.chatClient(withToken: token, properties: nil, delegate: self) {
                    (result, chatClient) in
                        self.client = chatClient;
                        self.createGeneralChannelIfNeeded()
                        completion(result)
                    }
            } else {
                print("Error retrieving token: \(error.debugDescription)")
            }
            
        }
    }
    
    
    func logout() {
        if let client = client {
            client.delegate = nil
            client.shutdown()
            self.client = nil
        }
    }
    
    func createGeneralChannelIfNeeded() {
        // Create the general channel (for public use) if it hasn't been created yet
        
        let options = [
            TCHChannelOptionFriendlyName: "General Channel",
            TCHChannelOptionType: TCHChannelType.public.rawValue
            ] as [String : Any]
        if let client = client, let channelsList = client.channelsList() {
            channelsList.createChannel(options: options, completion: { channelResult, channel in
                if (channelResult.isSuccessful()) {
                    print("Channel created.")
                } else {
                    print("Channel NOT created.")
                }
            })
        }
    }
}
