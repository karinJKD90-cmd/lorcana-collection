# Lorcana App — Wijzigingslog voor nieuwe app

Elke sectie beschrijft een gevraagde wijziging met voldoende detail om zelfstandig te implementeren.

---

<!-- Nieuwe wijzigingen worden hier onder toegevoegd -->

---

## #5 — CardGridView: filter-header pass 2 (multiselect, inkt, SIG, layout)

**Bestand:** `Views/Collection/CardGridView.swift`

Tweede redesign-ronde van de filter-header op basis van visuele feedback.

### Rarity: multiselect + zichtbaarder

`selectedRarity: String?` vervangen door `selectedRarities: Set<String>`. Chips zijn nu togglebaar: tik op meerdere rarities om ze tegelijk te activeren. Inactieve chips vervagen (opacity 0.12, saturation 0) wanneer er een selectie actief is. Actieve chip krijgt goudkleurige top-border (1.5 px) plus lichte achtergrondtint.

```swift
// Was:
@State private var selectedRarity: String? = nil

// Nu:
@State private var selectedRarities: Set<String> = []
```

Iconen vergroot naar 30 px (was 24 px), minder verticale padding zodat de rij compacter is. Labels blijven zichtbaar maar kleiner (7.5 pt), vervagen mee bij inactiviteit.

Filter-logica:
```swift
.filter { selectedRarities.isEmpty || selectedRarities.contains($0.rarity) }
```

`onAppear` aangepast:
```swift
if let r = initialRarity { selectedRarities = [r] }
```

`onChange` gecorrigeerd:
```swift
.onChange(of: selectedRarities) { scheduleFilter() }
```

"Clear"-chip verschijnt conditoneel rechts van SIG zodra er een rarity of SIG actief is:
```swift
if !selectedRarities.isEmpty || showOnlySigned {
    Button { selectedRarities = []; showOnlySigned = false } label: { ... }
}
```

### SIG-chip toegevoegd

Nieuw filter-chip direct na de rarity-chips (gescheiden door een dunne divider). Icoon is een pen-nib getekend via `Canvas` — geen SF Symbol-afhankelijkheid. Kleuraccent is groen (`#3A9D5D`) wanneer actief, past in hetzelfde chip-systeem als rarity.

```swift
Canvas { ctx, size in
    // Diamond nib
    var nib = Path()
    nib.move(to: CGPoint(x: w * 0.50, y: h * 0.04))
    nib.addLine(to: CGPoint(x: w * 0.82, y: h * 0.38))
    nib.addLine(to: CGPoint(x: w * 0.50, y: h * 0.62))
    nib.addLine(to: CGPoint(x: w * 0.18, y: h * 0.38))
    nib.closeSubpath()
    ctx.fill(nib, with: .color(col.opacity(0.18)))
    ctx.stroke(nib, with: .color(col), style: StrokeStyle(lineWidth: 1.3))
    // Spleet
    var slit = Path()
    slit.move(to: CGPoint(x: w * 0.50, y: h * 0.30))
    slit.addLine(to: CGPoint(x: w * 0.50, y: h * 0.62))
    ctx.stroke(slit, with: .color(col), style: StrokeStyle(lineWidth: 0.9))
    // Handvat
    var handle = Path()
    handle.move(to: CGPoint(x: w * 0.50, y: h * 0.62))
    handle.addLine(to: CGPoint(x: w * 0.35, y: h * 0.96))
    ctx.stroke(handle, with: .color(col), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
}
.frame(width: 30, height: 30)
```

### Inkt-filter: geen rondjes, geen labels

Inkt-iconen tonen nu direct (30 px) zonder omringende cirkel of tekst. Actieve state: kleur-specifieke achtergrondtint + border. Inactieve iconen vervagen (opacity 0.10, saturation 0.10) bij actieve selectie.

```swift
ZStack {
    if isActive {
        color.opacity(0.12)
        Rectangle().strokeBorder(color.opacity(0.45), lineWidth: 0.6)
    }
    Image("ink_\(ink.lowercased())")
        .resizable().scaledToFit().frame(width: 30, height: 30)
        .opacity(hasSel && !isActive ? 0.10 : 1.0)
        .saturation(hasSel && !isActive ? 0.10 : 1.0)
}
.frame(maxWidth: .infinity).frame(height: 46)
```

### Zoekbalk: # links, naam rechts

De twee zoekbalkken staan naast elkaar in één HStack. Kaartnummer (`#`) heeft vaste breedte links, naam heeft `frame(maxWidth: .infinity)` rechts.

### Sortering: rechts uitgelijnd

`Spacer()` staat nu als eerste in de sort-HStack zodat de sort-knoppen rechts uitlijnen. Reset-knop verschijnt links van de divider wanneer er een actief filter is.

### Reset-knop (sort-rij)

Wist nu ook `searchText` en `cardNumberSearch`, naast ink/rarity/sig/sort:
```swift
let hasFilter = selectedInk != nil || !selectedRarities.isEmpty || showOnlySigned
    || sortMode != .cardNumber || !searchText.isEmpty || !cardNumberSearch.isEmpty
```

---

## #4 — CardGridView: filter-header herschreven

**Bestand:** `Views/Collection/CardGridView.swift`

Volledige redesign van de filter-header. Nieuwe volgorde en toevoegingen:

**1. Rarity (bovenaan)** — horizontaal scrollbaar, nu met echte image assets (`rarity_common`, `rarity_uncommon`, etc.) in plaats van code-drawn shapes. "All"-chip gebruikt de bestaande multi-shape preview. `Special_rarity` valt terug op `rarity_promo`.

**2. Zoeken** — twee compacte velden naast elkaar: naam (tekst) en kaartnummer (`#`, numeriek toetsenbord). Beide debounced (150ms). Reset-knopje per veld.

**3. Ink filter** — bestaande portal-icons, licht compacter (36px cirkel i.p.v. 40px).

**4. Sort + SIG + reset** — ongewijzigd qua functie, licht compacter. Reset wist nu ook de zoekbalk.

**Nieuwe `@State` vars:**
```swift
@State private var searchText = ""
@State private var cardNumberSearch = ""
```

**Filter-logica in `computeFilter()`:**
```swift
.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
.filter { card in cardNumberSearch.isEmpty || Int(cardNumberSearch).map { $0 == card.cardNumber } ?? false }
```

**Asset-mapping rarity → image:**
- `Special_rarity` → `rarity_promo` (fallback)
- Overige: `rarity_\(rarity.lowercased())`

---

## #3 — Dashboard: top 5 klikbaar + "show all" knop

**Bestanden:** `Views/Dashboard/DashboardView.swift`, `Views/Collection/CardGridView.swift`

### DashboardView
De top 5 kaarten zijn nu klikbaar via `NavigationLink` → `CardPageView`. De kaart die je aanklikt opent direct op de juiste positie in de pageable detail-view (via `currentIndex`). Onder het top 5 blok staat een "show all →" link die navigeert naar de volledige collectie gesorteerd op hoogste prijs.

```swift
// Elke kaart in top 5:
NavigationLink(destination: CardPageView(cards: topCards, currentIndex: index)) { ... }

// Show all knop:
NavigationLink(destination: CardGridView(
    setNumber: nil,
    setName: "All cards",
    initialSortMode: .priceDesc,
    filterOwned: true
)) {
    HStack(spacing: 4) {
        Text("show all").font(.system(size: 11, design: .monospaced))
        Image(systemName: "chevron.right").font(.system(size: 9))
    }
}
```

### CardGridView
Twee nieuwe parameters toegevoegd:

```swift
var initialSortMode: SortMode? = nil   // preset de sortering bij openen
var filterOwned: Bool = false          // toont alleen owned kaarten wanneer true
```

- `filterOwned` wordt toegepast in `computeFilter()` als extra `.filter { !filterOwned || $0.owned }`
- `initialSortMode` wordt opgepikt in `.onAppear { if let s = initialSortMode { sortMode = s } }`

---

## #2 — Rarity-iconen toegevoegd als image assets

**Locatie:** `Assets.xcassets/`

Negen officiële Lorcana rarity-iconen zijn toegevoegd als volwaardige Xcode imagesets (elk met `Contents.json`). De asset-namen zijn:

| Asset naam | Bestandsnaam |
|---|---|
| `rarity_common` | `1280px-Common.png` |
| `rarity_uncommon` | `1280px-Uncommon.png` |
| `rarity_rare` | `1920px-Rare.png` |
| `rarity_super_rare` | `1280px-Super_Rare.png` |
| `rarity_legendary` | `1920px-Legendary.png` |
| `rarity_enchanted` | `1024px-Enchanted.png` |
| `rarity_epic` | `Epic.png` |
| `rarity_iconic` | `Iconic.png` |
| `rarity_promo` | `1280px-Promo.png` |

**Gebruik in SwiftUI:**
```swift
Image("rarity_common")
Image("rarity_legendary")
// etc.
```

**Let op:** De app tekent rarity-iconen momenteel nog programmatisch via `RarityPipIcon` in `SharedComponents.swift`. De image assets zijn beschikbaar maar vervangen de code-drawn shapes nog niet automatisch — dat is een aparte stap.

---

## #1 — Featured tile: subtitel verwijderen

**Bestand:** `Views/Home/HomeView.swift`  
**Component:** Featured set-tegel op de home screen (de brede banner met set-naam)

**Wijziging:** De subtitel `· continue your quest ·` boven de set-naam is verwijderd. De `VStack` bevat nu alleen nog de set-naam (`Text(cardSet.name)`) en wat daaronder staat.

**Voor:**
```swift
VStack(alignment: .leading, spacing: 3) {
    Text("· continue your quest ·")
        .font(.system(size: 8.5, design: .monospaced))
        .tracking(3)
        .foregroundStyle(Color(hex: "#8A7A4A"))

    Text(cardSet.name)
        ...
}
```

**Na:**
```swift
VStack(alignment: .leading, spacing: 3) {
    Text(cardSet.name)
        ...
}
```
