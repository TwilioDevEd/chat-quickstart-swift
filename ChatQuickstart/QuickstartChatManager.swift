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
    private let tokenURL = "https://YOUR_TWILIO_FUNCTION_DOMAIN_HERE.twil.io/chat-token"
    
    private let channelName = "general"
    
    var chatManagerDelegate: QuickstartChatManagerDelegate?
    
    // MARK: Chat variables
    private var client: TwilioChatClient? = nil
    private var channel: TCHChannel? = nil
    private(set) var messages: [TCHMessage] = []
    
    func chatClient(_ client: TwilioChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
        guard status == .completed else {
            return
        }
        checkChannelCreation { (created) in
            if created {
                self.joinChannel()
            } else {
                self.createChannel() {
                    self.joinChannel()
                }
            }
        }
        
    }
    
    // Called whenever a channel we've joined receives a new message
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel,
                    messageAdded message: TCHMessage) {
        messages.append(message)
        
        DispatchQueue.main.async() {
            if let delegate = self.chatManagerDelegate {
                delegate.reloadMessages()
                if self.messages.count > 0 {
                    delegate.scrollToBottomMessage()
                }
            }
        }
    }
    
    func sendMessage(_ messageText:String, completion: @escaping (TCHResult, TCHMessage?) -> Void) {
        if let messages = self.channel?.messages {
            let messageOptions = TCHMessageOptions().withBody(messageText)
            messages.sendMessage(with: messageOptions, completion: { (result, message) in
                completion(result, message)
            })
        }
    }
    
    
    func login(_ identity:String, completion:@escaping (Bool)->Void) {
        // Fetch Access Token from the server and initialize Chat Client - this assumes you are
        // calling a Twilio function, as described in the Quickstart docs
        let urlString = "\(tokenURL)?identity=\(identity)"
        
        TokenUtils.retrieveToken(url: urlString) { (token, identity, error) in
            guard let token = token else {
                print("Error retrieving token: \(error.debugDescription)")
                completion(false)
                return
            }
            // Set up Twilio Chat client
            TwilioChatClient.chatClient(withToken: token, properties: nil, delegate: self) {
                (result, chatClient) in
                self.client = chatClient
                completion(result.isSuccessful())
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
    
    private func createChannel(_ completion: @escaping () -> Void) {
        guard let client = client, let channelsList = client.channelsList() else {
            return
        }
        // Create the channel if it hasn't been created yet
        let options = [
            TCHChannelOptionUniqueName: channelName,
            TCHChannelOptionFriendlyName: "General Channel",
            TCHChannelOptionType: TCHChannelType.public.rawValue
            ] as [String : Any]
        channelsList.createChannel(options: options, completion: { channelResult, channel in
            if (channelResult.isSuccessful()) {
                print("Channel created.")
            } else {
                print("Channel NOT created.")
            }
            completion()
        })
        
    }
    
    private func checkChannelCreation(_ completion: @escaping(Bool) -> Void) {
        guard let client = client, let channelsList = client.channelsList() else {
            return
        }
        channelsList.channel(withSidOrUniqueName: channelName, completion: { (result, channel) in
            completion(result.isSuccessful())
        })
    }
    
    private func joinChannel() {
        guard let client = client, let channelsList = client.channelsList() else {
            return
        }
        // Join the channel if needed
        channelsList.channel(withSidOrUniqueName: channelName, completion: { (result, channel) in
            guard let channel = channel else {
                return
            }
            self.channel = channel
            if channel.status == .joined {
                print("Current user already exists in channel")
            } else {
                channel.join(completion: { result in
                    print("Result of channel join: \(result.resultText ?? "No Result")")
                })
            }

        })
    }
}
