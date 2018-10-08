# Chat iOS Quickstart for Swift

Looking for Objective-C instead? [Check out this application](https://github.com/TwilioDevEd/chat-quickstart-objc).

In this guide, we will get you up and running quickly with a sample application
you can build on as you learn more about Chat. Sound like a plan? Then
let's get cracking!

## Gather Account Information

The first thing we need to do is grab all the necessary configuration values from our
Twilio account. To set up our back-end for Chat, we will need four 
pieces of information:

| Config Value  | Description |
| :-------------  |:------------- |
Service Instance SID | Like a database for your Chat data - [generate one in the console here](https://www.twilio.com/console/chat/services)
Account SID | Your primary Twilio account identifier - find this [in the console here](https://www.twilio.com/console/chat/getting-started).
API Key | Used to authenticate - [generate one here](https://www.twilio.com/console/chat/dev-tools/api-keys).
API Secret | Used to authenticate - [just like the above, you'll get one here](https://www.twilio.com/console/chat/dev-tools/api-keys).
Mobile Push Credential SID | Used to send notifications from Chat to your app - [create one in the console here](https://www.twilio.com/console/chat/credentials) or learn more about [Chat Push Notifications in iOS](https://www.twilio.com/docs/api/chat/guides/push-notifications-ios).

## Create a Twilio Function

When you build your application with Twilio Chat, you will need two pieces - the client (this iOS app) and a server that returns access tokens. If you don't want to set up your
own server, you can use [Twilio Functions](https://www.twilio.com/docs/api/runtime/functions) to easily create this part of your solution. 

If you haven't used Twilio Functions before, it's pretty easy - Functions are a way to 
run your Node.js code in Twilio's environment. You can create new functions on the Twilio Console's [Manage Functions Page](https://www.twilio.com/console/runtime/functions/manage).

You will need to choose the "Programmable Chat Access Token" template, and then fill in the account information you gathered above. After you do that, the Function will appear, and you can read through it. Save it, and it will immediately be published at the URL provided - go ahead and put that URL into a web browser, and you should see a token being returned from your Function. If you are getting an error, check to make sure that all of your account information is properly defined.

Want to learn more about the code in the Function template, or want to write your own server code? Checkout the [Twilio Chat Identity Guide](https://www.twilio.com/docs/api/chat/guides/identity) for the underlying concepts.

Now that the Twilio Function is set up, let's get the starter iOS app up and running.

### Warning!

NOTE: You should not use Twilio Functions to generate access tokens for your app in production. Each function has a publicly accessible URL which a malicious actor could use to obtain tokens for your app and abuse them.

[Read more about access tokens here](https://www.twilio.com/docs/api/chat/guides/identity) to learn how to generate access tokens in your own C#, Java, Node.js, PHP, Python, or Ruby application.


## Configure and Run the Mobile App

Our mobile application manages dependencies via [Cocoapods](https://cocoapods.org/).
Once you have Cocoapods installed, download or clone this application project to
your machine.  To install all the necessary dependencies from Cocoapods, run:

```
pod install
```

Open up the project from the Terminal with:

```
open ChatQuickstart.xcworkspace
```

Note that you are opening the `.xcworkspace` file rather than the `xcodeproj`
file, like all Cocoapods applications. You will need to open your project this
way every time. 

You will need to go into `ChatViewController.swift` and modify the URL for your
Twilio Function there - each Twilio user will have a different domain to use for
their Twilio Functions.

```
let tokenURL = "https://YOUR_TWILIO_FUNCTION_DOMAIN_HERE.twil.io/chat-token"
```

You should now be able to press play and run the project in the 
simulator. 

Once the app loads in the simulator, you should see a UI like this one:

![quick start app screenshot](https://s3.amazonaws.com/howtodocs/ios-quickstart/iphone.png)

Start sending yourself a few messages - they should start appearing in the
`UITableView` in the starter app.

You're all set! From here, you can start building your own application. For guidance
on integrating the iOS SDK into your existing project, [head over to our install guide](https://www.twilio.com/docs/api/chat/sdks).

If you'd like to learn more about how Chat works, you might want to dive
into our [user identity guide](https://www.twilio.com/docs/api/chat/guides/identity), 
which talks about the relationship between the mobile app and the server.

Good luck and have fun!

## License

MIT
