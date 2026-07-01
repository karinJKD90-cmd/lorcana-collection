Lorcana Collection
iOS app for tracking your Disney Lorcana TCG collection. Built in Swift with SwiftData.
Features
Collection — mark cards as owned, foil, or signed. Tracks set completion and total value.
Scan — scan individual cards or booster packs with your camera via OCR.
Prices — card prices synced from Cardmarket. Price history per card.
Wishlist — priority wishlist for cards you're looking for.
Decks — build decks from owned cards with ink, cost and lore tracking.
Database — browse all Lorcana cards with filters for set, ink, rarity and type.
Backup — export collection to CSV or create a full local backup.
Stack
Swift / SwiftUI
SwiftData (local persistence)
Lorcana API — card data
Cardmarket — pricing
Claude Vision API — card recognition via camera
Requirements
Xcode 15+
iOS 17+
Apple Developer account (for device installation)
Setup
Clone the repo
Open LorcanaCollection.xcodeproj in Xcode
Add your Claude API key to Xcode's keychain (never hardcode it)
Select your device and run
Notes
Cardmarket scraping may break if their HTML structure changes
The Claude API key must be stored in Xcode keychain, not in source code

