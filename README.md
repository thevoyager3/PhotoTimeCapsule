# Photo Time Capsule

A simple iPhone app that looks through your photo library and shows every photo
you took **on this day in previous years**, grouped by year ("1 year ago",
"2 years ago", …).

- Opens on today's date, newest year first
- Tap the calendar button to look at any other day
- Tap a photo to see it full screen; swipe left and right to move between photos from that year
- Pull down to refresh
- Photos stored only in iCloud are downloaded automatically
- Everything happens on the phone; no photo is uploaded anywhere

Built with SwiftUI and Apple's Photos framework. Requires iOS 17 or later.

## Running it on your iPhone (first time)

You need a Mac with **Xcode 16 or newer** (free from the Mac App Store) and a
free Apple ID. A paid developer account is not needed to run it on your own phone.

1. **Get the code on your Mac.** Clone this repository, or download it as a ZIP
   from GitHub (green *Code* button → *Download ZIP*) and unzip it.
2. **Open the project.** Double-click `PhotoTimeCapsule.xcodeproj`.
3. **Sign in to Xcode.** *Xcode → Settings → Accounts → +* → add your Apple ID.
4. **Set up signing.** In the left sidebar click the blue **PhotoTimeCapsule**
   project icon, select the **PhotoTimeCapsule** target, open the
   **Signing & Capabilities** tab, then:
   - pick your name under **Team**
   - change **Bundle Identifier** from `com.example.PhotoTimeCapsule` to something
     unique, e.g. `com.yourname.PhotoTimeCapsule`
5. **Connect your iPhone** with a cable and unlock it. Tap *Trust* if asked.
6. **Turn on Developer Mode** on the iPhone: *Settings → Privacy & Security →
   Developer Mode* → on (the phone restarts). This option only appears after the
   phone has been connected to Xcode once.
7. **Run.** At the top of the Xcode window, choose your iPhone from the device
   menu, then press the ▶︎ (Run) button or ⌘R.
8. **Trust yourself as a developer** (first run only). If the iPhone says
   "Untrusted Developer", go to *Settings → General → VPN & Device Management*,
   tap your Apple ID and tap *Trust*. Then run again.
9. When the app asks for access to your photos, choose **Allow Full Access**.

> With a free Apple ID, apps you install this way stop opening after 7 days.
> Just connect the phone and press Run again to renew it. A paid Apple Developer
> Program membership ($99/year) extends this to a year and lets you publish to
> the App Store or TestFlight.

### Trying it in the Simulator

You can also pick any iPhone simulator from the device menu and press Run. The
simulator has only a few sample photos, so drag some of your own photos onto the
simulator window to add them to its library. (Their dates are kept, so older
photos will show up under the right years.)

## How the code is organised

All the code is in the `PhotoTimeCapsule/` folder:

| File | What it does |
| --- | --- |
| `PhotoTimeCapsuleApp.swift` | The app's entry point. |
| `ContentView.swift` | The main screen: asking for permission, the year-by-year photo grids and the day picker. |
| `PhotoLibrary.swift` | Asks for photo access and searches the library for photos taken on the same day in each earlier year. |
| `AssetImage.swift` | Loads and draws one photo at the right size for the screen. |
| `PhotoDetailView.swift` | The full-screen, swipeable photo viewer. |

The permission message the user sees ("Time Capsule looks through your photo
library…") is set in the project's build settings as
`NSPhotoLibraryUsageDescription` (target → *Info* tab).

## Ideas for next steps

- Include videos and Live Photos
- A daily notification: "You have 12 memories from today"
- A home-screen widget showing a random photo from this day
- A share button in the full-screen viewer
