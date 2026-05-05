# Webapp Migratieplan — Lorcana Collection

**Situatie:** iOS SwiftUI/SwiftData app → Single-user webapp met cloud storage  
**Stack keuze:** Next.js + Supabase + Vercel  
**Datum:** 28 april 2026

---

## Stack — waarom dit

| Onderdeel | Keuze | Reden |
|---|---|---|
| Frontend | **Next.js** (React) | Beste DX, werkt op elk apparaat, makkelijk te deployen |
| Database + Auth | **Supabase** | Managed PostgreSQL, auth ingebouwd, gratis tier ruim genoeg, geen server |
| Hosting | **Vercel** | Gratis voor personal use, nul configuratie met Next.js |
| Afbeeldingen | **Lorcast API** | Kaartplaatjes komen al van de API — niets op te slaan |

Supabase is in feite een hosted PostgreSQL-database met een ingebouwde REST/realtime API en authenticatie. Je betaalt niets tenzij je gigantisch groeit. Voor één gebruiker is het onbeperkt gratis.

---

## Data model — SwiftData → PostgreSQL

Directe vertaling van je bestaande modellen:

```sql
-- Vervanger van Card (SwiftData)
CREATE TABLE cards (
  id TEXT PRIMARY KEY,              -- Lorcast API id
  name TEXT NOT NULL,
  set_name TEXT,
  set_number INTEGER,
  card_number INTEGER,
  rarity TEXT,
  ink TEXT,
  cost INTEGER,
  strength INTEGER,
  willpower INTEGER,
  lore INTEGER,
  card_type TEXT,
  image_url TEXT,
  -- Gebruikersstatus
  owned BOOLEAN DEFAULT FALSE,
  is_foil BOOLEAN DEFAULT FALSE,
  is_signed BOOLEAN DEFAULT FALSE,
  in_priority_wishlist BOOLEAN DEFAULT FALSE,
  quantity INTEGER DEFAULT 0,
  -- Persoonlijke data
  purchase_price DECIMAL(10,2),
  purchase_date DATE,
  notes TEXT,
  -- Prijzen
  current_price_normal DECIMAL(10,2),
  current_price_foil DECIMAL(10,2),
  last_price_update TIMESTAMPTZ
);

-- Vervanger van Deck
CREATE TABLE decks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_modified TIMESTAMPTZ DEFAULT NOW()
);

-- Vervanger van DeckEntry
CREATE TABLE deck_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deck_id UUID REFERENCES decks(id) ON DELETE CASCADE,
  card_id TEXT REFERENCES cards(id),
  quantity INTEGER DEFAULT 1
);

-- Vervanger van PricePoint
CREATE TABLE price_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recorded_at TIMESTAMPTZ DEFAULT NOW(),
  total_collection_value DECIMAL(10,2)
);
```

---

## Features — mapping iOS → Web

| Feature | iOS | Web |
|---|---|---|
| Collectie bijhouden | SwiftData | Supabase tabel `cards` |
| Deck builder | SwiftData relaties | `decks` + `deck_entries` tabellen |
| Prijzen + historie | PricePoint model | `price_history` tabel |
| Lorcast API sync | LorcanaAPIService.swift | Zelfde API, fetch() in Next.js |
| CSV export/import | CSVService.swift | Client-side in browser (eenvoudiger) |
| JSON backup | BackupService.swift | Download JSON rechtstreeks vanuit Supabase |
| OCR scannen | Vision framework (iOS) | ⚠️ Zie aparte sectie hieronder |
| Afbeeldingen | ImageCache.swift | Niet nodig — direct van Lorcast URL |
| Auth | Geen (lokaal) | Supabase Auth — magic link of email/ww |

### ⚠️ OCR scannen in de browser

Dit is de enige feature die significant anders werkt:

- **Optie A (aanbevolen):** Tesseract.js — volledig client-side OCR, werkt in de browser zonder server. Minder nauwkeurig dan Apple Vision, maar geen kosten.
- **Optie B:** Google Vision API — accurater, maar kost geld per scan (~$1,50 per 1000 scans).
- **Optie C:** Weglaten in eerste versie, later toevoegen.

Voor persoonlijk gebruik is Tesseract.js prima. De scan-flow wordt: foto uploaden → OCR in browser → kaartnummer matchen aan Lorcast API.

---

## Fases

### Fase 1 — Fundament (1-2 dagen werk)
1. Supabase project aanmaken, tabellen aanmaken (SQL hierboven)
2. Next.js project bootstrappen (`npx create-next-app`)
3. Supabase client koppelen (`@supabase/supabase-js`)
4. Eenvoudige auth: magic link naar je eigen e-mailadres
5. Deployen op Vercel

**Resultaat:** Lege webapp die je kunt inloggen.

### Fase 2 — Collectie (2-3 dagen werk)
1. Lorcast API sync bouwen (sets ophalen, kaarten in Supabase laden)
2. Collectieweergave: kaartgrid per set
3. Owned/foil/signed/wishlist toggles
4. Kaartdetail pagina

**Resultaat:** Je kunt kaarten bekijken en je collectie bijhouden.

### Fase 3 — Data migreren (1 dag)
1. In de iOS app: BackupService → exporteer JSON
2. Migratiescript schrijven (Node.js, ~50 regels) dat de JSON inleest en naar Supabase pusht
3. Verifiëren of alles klopt

**Resultaat:** Bestaande collectie staat in de cloud.

### Fase 4 — Deck builder + prijzen (2-3 dagen werk)
1. Deck builder UI
2. Prijzen ophalen (Cardmarket/Lorcast), opslaan
3. Dashboard met collectiewaarde

### Fase 5 — OCR scannen (optioneel, 2-3 dagen)
1. Tesseract.js integreren
2. Camera/foto upload → kaart herkennen → collectie updaten

---

## Migratie bestaande data — stap voor stap

```
iOS app → Instellingen → Backup exporteren → lorcana_backup_DATUM.json
                                    ↓
              Migratiescript (Node.js) leest JSON
                                    ↓
              Supabase API / SQL INSERT voor elke kaart
                                    ↓
              Verifieer in Supabase dashboard
```

Het JSON formaat van je BackupService is al goed gestructureerd — migratie is relatief eenvoudig.

---

## Kosten

| Service | Kosten |
|---|---|
| Supabase (Free tier) | €0 — 500MB database, 1GB opslag, 50.000 MAU |
| Vercel (Hobby) | €0 — onbeperkt voor persoonlijk gebruik |
| Domein (optioneel) | ~€10/jaar |
| **Totaal** | **€0 — €10/jaar** |

---

## Volgende stap

Kies een startpunt:

1. **Ik stel de Supabase database op** — tabellen aanmaken, schema deployen
2. **Ik bootstrap het Next.js project** — basisstructuur, auth, Supabase koppeling
3. **Ik schrijf het migratiescript** — iOS JSON → Supabase import

Of alles tegelijk als je er klaar voor bent.
