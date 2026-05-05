-- ─────────────────────────────────────────────────────────────────────────────
-- Lorcana Collection – Supabase database schema
-- Plak dit in: Supabase dashboard → SQL Editor → New query → Run
-- ─────────────────────────────────────────────────────────────────────────────

-- Kaarten (één rij per kaart per gebruiker)
CREATE TABLE cards (
  id                    TEXT NOT NULL,
  user_id               UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name                  TEXT NOT NULL,
  set_name              TEXT,
  set_number            INTEGER,
  card_number           INTEGER,
  rarity                TEXT,
  ink                   TEXT,
  cost                  INTEGER DEFAULT 0,
  strength              INTEGER DEFAULT 0,
  willpower             INTEGER DEFAULT 0,
  lore                  INTEGER DEFAULT 0,
  card_type             TEXT,
  image_url             TEXT,

  -- Gebruikersstatus
  owned                 BOOLEAN DEFAULT FALSE,
  is_foil               BOOLEAN DEFAULT FALSE,
  is_signed             BOOLEAN DEFAULT FALSE,
  in_priority_wishlist  BOOLEAN DEFAULT FALSE,
  quantity              INTEGER DEFAULT 0,

  -- Persoonlijk
  purchase_price        DECIMAL(10,2),
  notes                 TEXT,

  -- Prijzen
  current_price_normal  DECIMAL(10,2),
  current_price_foil    DECIMAL(10,2),
  last_price_update     TIMESTAMPTZ,

  PRIMARY KEY (id, user_id)
);

-- Decks
CREATE TABLE decks (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  notes         TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  last_modified TIMESTAMPTZ DEFAULT NOW()
);

-- Deck entries
CREATE TABLE deck_entries (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deck_id   UUID NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
  card_id   TEXT NOT NULL,
  card_name TEXT,
  image_url TEXT,
  quantity  INTEGER DEFAULT 1 CHECK (quantity BETWEEN 1 AND 4)
);

-- Prijshistorie
CREATE TABLE price_history (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recorded_at            TIMESTAMPTZ DEFAULT NOW(),
  total_collection_value DECIMAL(10,2)
);

-- ─── Row Level Security ───────────────────────────────────────────────────────
-- Gebruikers kunnen ALLEEN hun eigen data zien en wijzigen.

ALTER TABLE cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE decks ENABLE ROW LEVEL SECURITY;
ALTER TABLE deck_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_history ENABLE ROW LEVEL SECURITY;

-- Cards
CREATE POLICY "Eigen kaarten" ON cards
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Decks
CREATE POLICY "Eigen decks" ON decks
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Deck entries (via deck eigenaarschap)
CREATE POLICY "Eigen deck entries" ON deck_entries
  USING (EXISTS (SELECT 1 FROM decks WHERE decks.id = deck_entries.deck_id AND decks.user_id = auth.uid()));

-- Prijshistorie
CREATE POLICY "Eigen prijshistorie" ON price_history
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── Indexen voor snelheid ────────────────────────────────────────────────────
CREATE INDEX idx_cards_user_set ON cards(user_id, set_number, card_number);
CREATE INDEX idx_cards_owned ON cards(user_id, owned) WHERE owned = TRUE;
CREATE INDEX idx_decks_user ON decks(user_id);
