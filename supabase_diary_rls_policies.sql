-- Diary Tablosu RLS Politikaları
-- Supabase SQL Editor'de çalıştırın

-- Önce mevcut politikaları sil (varsa)
DROP POLICY IF EXISTS "Users can view their own diary entries" ON diary;
DROP POLICY IF EXISTS "Users can insert their own diary entries" ON diary;
DROP POLICY IF EXISTS "Users can update their own diary entries" ON diary;
DROP POLICY IF EXISTS "Users can delete their own diary entries" ON diary;

-- RLS'yi etkinleştir
ALTER TABLE diary ENABLE ROW LEVEL SECURITY;

-- SELECT politikası: Kullanıcılar sadece kendi verilerini görebilir
CREATE POLICY "Users can view their own diary entries"
ON diary FOR SELECT
TO authenticated
USING (auth.uid()::text = user_id);

-- INSERT politikası: Kullanıcılar sadece kendi verilerini ekleyebilir
CREATE POLICY "Users can insert their own diary entries"
ON diary FOR INSERT
TO authenticated
WITH CHECK (auth.uid()::text = user_id);

-- UPDATE politikası: Kullanıcılar sadece kendi verilerini güncelleyebilir
CREATE POLICY "Users can update their own diary entries"
ON diary FOR UPDATE
TO authenticated
USING (auth.uid()::text = user_id)
WITH CHECK (auth.uid()::text = user_id);

-- DELETE politikası: Kullanıcılar sadece kendi verilerini silebilir
CREATE POLICY "Users can delete their own diary entries"
ON diary FOR DELETE
TO authenticated
USING (auth.uid()::text = user_id);


