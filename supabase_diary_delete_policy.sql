-- Diary Tablosu DELETE RLS Politikası
-- Supabase SQL Editor'de çalıştırın

-- Mevcut DELETE politikasını sil (varsa)
DROP POLICY IF EXISTS "Users can delete their own diary entries" ON diary;
DROP POLICY IF EXISTS "Users can delete their own diary" ON diary;
DROP POLICY IF EXISTS "Authenticated users can delete their own diary" ON diary;

-- RLS'yi etkinleştir (eğer etkin değilse)
ALTER TABLE diary ENABLE ROW LEVEL SECURITY;

-- DELETE politikası: Kullanıcılar sadece kendi kayıtlarını silebilir
CREATE POLICY "Users can delete their own diary entries"
ON diary FOR DELETE
TO authenticated
USING (auth.uid()::text = user_id);


