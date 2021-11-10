# PhotoCrowd
A native iOS application powered by Flickr's API.

## Details
PhotoCrowd is a photo viewing app in which users can browse endless photos from Flickr from either the most recent photos uploaded to Flickr, or searching by tag.

Any post can also be more closely viewed by tapping on the post. Relevant information to the post will be displayed as well as comments of the post if any.

A user can also add a comment or add the post to their favorites if they log into Flickr or create a Flickr account.

## Technology
Before plunging into the project, I designed a light version of the expected UI using Sketch and continuously updated it as development went along.

This project is written in native Swift, iOS environment and was built using Storyboard and UIKit. When downloading from the URL, I specified JSON format so as to use Swift's JSON parser to garner data.

To store data and keep the project organized, I incorporated the use of MVC with an empathesis in using classes to hold parsed JSON data and share between views.

To let users login, Flickr uses OAuth which was incorporated into this project with the help of [OAuthSwift](https://github.com/OAuthSwift/OAuthSwift). This external project assisted in making web requests to the OAuth service and returning responses.

Lastly, when handling sensitive user data, I incorporated the use of Apple's Keychain and used an externally built wrapper [SwiftKeychainWrapper](https://github.com/jrendel/SwiftKeychainWrapper) to simplify storing the sensitive data.


## "How Can I Run this Project Myself?"
If you take a look at the '.gitignore' file, you will notice that a few files are missing that you will need to download or create. First, you must clone the project onto your device. Then download the following projects, add them to your cloned 'PhotoCrowd' project, and ensure that they are added to your framework in - Project Target/Build Phases/Dependencies:
### [SwiftKeychainWrapper](https://github.com/jrendel/SwiftKeychainWrapper)
### [OAuthSwift](https://github.com/OAuthSwift/OAuthSwift)

Next, create the following file in the 'Utilities' folder:

Keys.xcconfig

In this file, you need to add the following two lines and nothing more as the project is designed to take the plain text of your API key and secret and make it a string:

API_KEY = (YOUR API KEY IN PLAIN TEXT)
API_SECRET = (YOUR API SECRET IN PLAIN TEXT)

### You are now ready to run the project and discover the PhotoCrowd!