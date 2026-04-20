---

## Faseplan

### Fase 1 - Basis
- Lorcana API integratie
- Kaarten bekijken en zoeken
- UI basisstructuur

### Fase 2 - Collectie
- SwiftData opslag
- Normaal/foil toggles
- Collectieoverzicht

### Fase 3 - Prijzen
- Cardmarket scraping
- Sync knop
- Totaalwaarde berekening

### Fase 4 - Scannen
- Fotoherkenning via Claude Vision
- Barcode scanner

### Fase 5 - Video
- Videoanalyse via Claude Vision

---

## Belangrijke notes

- App gaat niet naar App Store; installatie via Xcode (USB) of Apple Developer account
- Claude heeft geen geheugen tussen sessies; altijd huidige code plakken als context
- Cardmarket scraping kan breken bij HTML wijzigingen
- Claude API key opslaan in Xcode keychain, nooit in code
  
