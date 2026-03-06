# Claude Code Prompt: "Atlas" — A Curated Urban Art, Culture & Design Discovery App

## What We're Building

**Atlas** is an iOS app for discovering design-forward art, culture, and architecture in cities around the world. Think of it as "Boutique Homes' curatorial eye, applied to the cultural life of cities" — or "the Monocle city guide as a native app with location awareness."

The user browses beautifully presented, editorially curated places (galleries, studios, architectural landmarks, design shops, cultural institutions, street art, hidden courtyards, etc.), saves them to personal collections, and then — when physically in that city — gets location-aware prompts and richer on-site content as they explore.

It is NOT a reviews app (no Yelp/TripAdvisor vibes). It is NOT a booking app. It is an editorial discovery tool with a strong design point of view. The tone is confident, spare, opinionated — more Kinfolk than Lonely Planet.

---

## Core User Flows (V1)

### Flow 1: Browse & Discover (at home or anywhere)
- Open app → see a curated feed of featured places, organized by city
- Tap into a city → see an editorial city overview + categorized places
- Tap a place → see a rich detail view: hero image, short editorial description, category tags, location on map, practical info (hours, address, free/paid)
- Save places to personal collections (e.g., "Tokyo November Trip", "Favorites")

### Flow 2: Explore On-Site (in a city)
- App detects user is in a city that has Atlas content
- Surfaces a contextual "You're in [City]" experience
- Map view shows nearby curated places with distance
- Optional: gentle notification when user is within ~200m of an Atlas place ("The Noguchi Museum is a 3-minute walk from you")
- Place detail view shows richer "on-site" content (e.g., "Don't miss the sunken sculpture garden behind the main building")

### Flow 3: Collections & Lists
- Save any place to one or more personal collections
- Default collection: "Saved"
- Create custom collections with name + optional cover image
- Collections are the primary way users plan trips

---

## Data Model

### City
- `id`: UUID
- `name`: String (e.g., "Mexico City")
- `country`: String
- `slug`: String (url-safe)
- `heroImageURL`: String
- `editorialIntro`: String (2-3 sentences, the Atlas "take" on this city)
- `latitude` / `longitude`: Double (city center, for geo queries)
- `placeCount`: Int

### Place
- `id`: UUID
- `cityId`: UUID (FK → City)
- `name`: String
- `category`: Enum — one of: `gallery`, `museum`, `architecture`, `designShop`, `studio`, `streetArt`, `publicSpace`, `culturalInstitution`, `cafe`, `bookshop`, `other`
- `heroImageURL`: String
- `thumbnailURL`: String
- `editorialDescription`: String (3-5 sentences, opinionated, never generic)
- `onSiteTip`: String? (optional — only shows when user is nearby)
- `address`: String
- `latitude` / `longitude`: Double
- `neighborhood`: String? (e.g., "Coyoacán", "Shimokitazawa")
- `hours`: String? (e.g., "Wed–Mon 10am–6pm, closed Tue")
- `priceIndicator`: Enum — `free`, `$`, `$$`, `$$$`
- `websiteURL`: String?
- `tags`: [String] (e.g., ["brutalist", "contemporary art", "rooftop", "hidden gem"])
- `isFeatured`: Bool

### Collection (local, on-device for V1)
- `id`: UUID
- `name`: String
- `coverImageURL`: String?
- `placeIds`: [UUID]
- `createdAt`: Date

---

## Seed Content (V1)

For the first version, pre-populate the app with **3 cities, ~15 places each** (45 total places). Use realistic mock data — real place names from these cities where possible, with placeholder editorial copy and SF Symbols or solid-color placeholder images.

### Seed Cities:
1. **New York City** — Noguchi Museum, Dia Beacon, The Met Breuer building (Brutalist icon), Judd Foundation, MoMA PS1, Storefront for Art and Architecture, The High Line, Green-Wood Cemetery, McNally Jackson, Center for Architecture, Pioneer Works, etc.
2. **Porto** — Livraria Lello, Serralves Museum & Park, Casa da Música (OMA/Koolhaas), São Bento Station tiles, Fundação de Serralves, MAAT extension, Rua Miguel Bombarda gallery district, Palácio de Cristal gardens, Clérigos Tower, Bolsa Palace Arab Room, etc.
3. **London** — Barbican Centre, Design Museum, Serpentine Pavilion, Leighton House Museum, Whitechapel Gallery, Goldfinger's Trellick Tower, Dennis Severs' House, Wellcome Collection, Maggie's Centre (Zaha Hadid), Maltby Street Market, etc.

Generate plausible editorial descriptions for each. The tone should be: confident, concise, slightly opinionated, design-literate. Never generic tourist-guide copy. Example:

> **Noguchi Museum** — "A sculptor's private universe in Long Island City. Noguchi designed every detail — the building, the garden, the way light falls on basalt. Go on a weekday afternoon when you might be the only person in the outdoor gallery. The gift shop is one of the best in the city."

---

## UI / Design Direction

### Design Principles
- **Editorial, not utilitarian.** This should feel like opening a beautifully designed magazine, not searching a database.
- **Photography-forward.** Large hero images. Let the visuals breathe. Minimal chrome.
- **Restrained palette.** Near-white backgrounds, near-black text, one accent color (warm terracotta/clay, `#B85042`). Very selective use of color.
- **Typography matters.** Use a serif for headlines (New York / system serif), sans-serif for body (SF Pro). Headlines should feel editorial, body should feel clean.
- **No clutter.** No star ratings, no review counts, no "Sponsored" badges, no ads. This is a curated space.
- **Generous whitespace.** Let elements breathe. Padding should feel luxurious, not cramped.

### Key Screens

1. **Home / Feed**
   - Top: subtle greeting or "Featured in [City]" header
   - Horizontally scrollable city cards (large, photo-forward)
   - Below: "Featured Places" vertical feed — large hero images with place name, city, category tag
   - Pull to refresh

2. **City Detail**
   - Full-bleed hero image of the city
   - Editorial intro text (the Atlas "take")
   - Category filter chips (horizontally scrollable): All, Galleries, Architecture, Design Shops, etc.
   - Grid or list of places, filterable by category
   - Map toggle — switch between list view and map view of all places in this city

3. **Place Detail**
   - Full-bleed hero image
   - Place name (large, serif)
   - Category tag + neighborhood tag
   - Editorial description
   - "On-site tip" card (if available — show this with a location pin icon, slightly different styling to hint it's for when you're there)
   - Practical info: address, hours, price, website link
   - Map snippet showing location
   - "Save to Collection" button
   - "Nearby" section: 2-3 other Atlas places within walking distance

4. **Map View** (accessible from City Detail or as a tab)
   - Apple Maps with custom-styled annotation pins (terracotta color)
   - Tapping a pin shows a compact card (image + name + category)
   - Tapping the card opens Place Detail
   - User location shown when in the city

5. **Collections Tab**
   - List of user's collections
   - Default "Saved" collection always present
   - Each collection shows cover image, name, place count
   - Tap into a collection → list of saved places
   - "+" button to create new collection

6. **Profile / Settings** (minimal for V1)
   - Just a gear icon → About, clear cache, placeholder for future auth

### Tab Bar (3 tabs for V1)
1. **Discover** (home feed icon)
2. **Map** (map icon — shows all places in nearest city or selected city)
3. **Saved** (bookmark icon — collections)

---

## Technical Architecture

### Platform & Stack
- **iOS 17+**, SwiftUI exclusively
- **Swift 5.9+**, strict concurrency where applicable
- **No third-party dependencies for V1.** Use only Apple frameworks:
  - SwiftUI for all UI
  - MapKit for maps
  - CoreLocation for user location & geofencing
  - SwiftData (or simple JSON + UserDefaults) for local persistence
  - Combine or async/await for data flow

### Data Layer (V1 — Local Only)
- All city/place data ships as a bundled JSON file in the app
- Collections stored locally via SwiftData or UserDefaults + Codable
- No backend, no API, no auth for V1
- Structure the code so a backend (REST or Firebase) can be swapped in later without rewriting views

### Location Features
- Request location permission on first launch (with good UX copy explaining why)
- Use `CLLocationManager` to detect which city the user is in
- Show distance to places when location is available
- Optional: register `CLCircularRegion` monitors for saved places to trigger local notifications (~200m radius)
- Graceful degradation: everything works without location, it's just enhanced with it

### Project Structure
```
Atlas/
├── App/
│   ├── AtlasApp.swift          # App entry point
│   └── ContentView.swift       # Tab bar root
├── Models/
│   ├── City.swift
│   ├── Place.swift
│   ├── PlaceCategory.swift
│   └── Collection.swift
├── Data/
│   ├── SeedData.json           # Bundled city + place data
│   ├── DataService.swift       # Loads and provides data
│   └── CollectionStore.swift   # Local persistence for collections
├── Features/
│   ├── Discover/
│   │   ├── DiscoverView.swift
│   │   ├── CityCardView.swift
│   │   └── FeaturedPlaceRow.swift
│   ├── City/
│   │   ├── CityDetailView.swift
│   │   ├── PlaceGridItem.swift
│   │   └── CategoryFilterBar.swift
│   ├── Place/
│   │   ├── PlaceDetailView.swift
│   │   ├── NearbyPlacesSection.swift
│   │   └── OnSiteTipCard.swift
│   ├── Map/
│   │   ├── MapView.swift
│   │   └── PlaceAnnotationView.swift
│   └── Collections/
│       ├── CollectionsView.swift
│       ├── CollectionDetailView.swift
│       └── AddToCollectionSheet.swift
├── Location/
│   ├── LocationManager.swift
│   └── ProximityMonitor.swift
├── Components/
│   ├── HeroImageView.swift     # Reusable async image with placeholder
│   ├── TagChip.swift
│   ├── PriceIndicator.swift
│   └── AtlasButton.swift
├── Theme/
│   ├── AtlasColors.swift       # Centralized color tokens
│   ├── AtlasTypography.swift   # Font styles
│   └── AtlasSpacing.swift      # Spacing constants
└── Resources/
    ├── Assets.xcassets
    └── SeedData.json
```

### Key Implementation Notes
- Use `@Observable` (Observation framework, iOS 17) for view models, not `ObservableObject`
- Use `@Environment` for dependency injection of DataService, LocationManager, CollectionStore
- Hero images: use `AsyncImage` with a solid-color placeholder (use the terracotta accent or a warm gray)
- For V1, images can be SF Symbols or solid colored rectangles — the layout and typography should carry the design even without real photography
- Map annotations should use a custom SwiftUI view (terracotta circle with category icon), not default pins
- Implement smooth transitions: `NavigationStack` with custom matched geometry effects where appropriate
- Support Dynamic Type and Dark Mode from the start

---

## What NOT to Build in V1
- No user accounts / authentication
- No backend / API
- No push notifications (only local notifications for proximity)
- No social features (sharing, following)
- No search (browse-only for now — the catalog is small enough)
- No onboarding tutorial (the app should be self-evident)
- No in-app purchases or subscriptions
- No audio content (that's a future layer)
- No creator/admin tools (future phase)

---

## Success Criteria for V1
1. App launches and shows a beautiful, editorial home feed with 3 cities
2. User can browse into a city, filter by category, view places on a map
3. User can tap into a place and read a compelling editorial description
4. User can save places to collections and create new collections
5. If user grants location access and is in one of the 3 cities, they see distance to places and get the "You're in [City]" experience
6. The app FEELS like a design object — someone who cares about design would screenshot it and share it
7. The code is clean, well-structured, and ready for a backend to be plugged in

---

## Tone Check
If this app were a physical object, it would be a Monocle city guide, not a Fodor's guidebook.
If it were a store, it would be a gallery bookshop, not a gift shop.
If it were a person, it would be the friend who always knows the one gallery you haven't been to yet.
