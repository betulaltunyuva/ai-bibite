-- Meals History Tablosu
-- Supabase SQL Editor'de çalıştırın

CREATE TABLE IF NOT EXISTS meals_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  date TEXT NOT NULL,
  meal_name TEXT NOT NULL,
  calories INTEGER NOT NULL DEFAULT 0,
  protein DOUBLE PRECISION NOT NULL DEFAULT 0,
  carbs DOUBLE PRECISION NOT NULL DEFAULT 0,
  fat DOUBLE PRECISION NOT NULL DEFAULT 0,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index ekle (performans için)
CREATE INDEX IF NOT EXISTS idx_meals_history_user_date ON meals_history(user_id, date);
CREATE INDEX IF NOT EXISTS idx_meals_history_date ON meals_history(date);

-- RLS (Row Level Security) Politikaları
ALTER TABLE meals_history ENABLE ROW LEVEL SECURITY;

-- Kullanıcılar sadece kendi verilerini görebilir
CREATE POLICY "Users can view their own meals history"
ON meals_history FOR SELECT
TO authenticated
USING (auth.uid()::text = user_id);

-- Kullanıcılar sadece kendi verilerini ekleyebilir
CREATE POLICY "Users can insert their own meals history"
ON meals_history FOR INSERT
TO authenticated
WITH CHECK (auth.uid()::text = user_id);

-- Kullanıcılar sadece kendi verilerini güncelleyebilir
CREATE POLICY "Users can update their own meals history"
ON meals_history FOR UPDATE
TO authenticated
USING (auth.uid()::text = user_id)
WITH CHECK (auth.uid()::text = user_id);

-- Kullanıcılar sadece kendi verilerini silebilir
CREATE POLICY "Users can delete their own meals history"
ON meals_history FOR DELETE
TO authenticated
USING (auth.uid()::text = user_id);


