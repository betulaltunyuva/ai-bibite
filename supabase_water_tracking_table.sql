-- Water Tracking Tablosu
-- Supabase SQL Editor'de çalıştırın

CREATE TABLE IF NOT EXISTS water_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  date TEXT NOT NULL,
  count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- Index ekle (performans için)
CREATE INDEX IF NOT EXISTS idx_water_tracking_user_date ON water_tracking(user_id, date);

-- RLS (Row Level Security) Politikaları
ALTER TABLE water_tracking ENABLE ROW LEVEL SECURITY;

-- Kullanıcılar sadece kendi verilerini görebilir
CREATE POLICY "Users can view their own water tracking"
ON water_tracking FOR SELECT
TO authenticated
USING (auth.uid()::text = user_id);

-- Kullanıcılar sadece kendi verilerini ekleyebilir
CREATE POLICY "Users can insert their own water tracking"
ON water_tracking FOR INSERT
TO authenticated
WITH CHECK (auth.uid()::text = user_id);

-- Kullanıcılar sadece kendi verilerini güncelleyebilir
CREATE POLICY "Users can update their own water tracking"
ON water_tracking FOR UPDATE
TO authenticated
USING (auth.uid()::text = user_id)
WITH CHECK (auth.uid()::text = user_id);

-- Kullanıcılar sadece kendi verilerini silebilir
CREATE POLICY "Users can delete their own water tracking"
ON water_tracking FOR DELETE
TO authenticated
USING (auth.uid()::text = user_id);


