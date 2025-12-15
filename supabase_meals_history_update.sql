-- Meals History Tablosuna meal_type ve description alanları ekle
-- Supabase SQL Editor'de çalıştırın

-- meal_type sütunu ekle (sabah, ogle, aksam)
ALTER TABLE meals_history 
ADD COLUMN IF NOT EXISTS meal_type TEXT;

-- description sütunu ekle
ALTER TABLE meals_history 
ADD COLUMN IF NOT EXISTS description TEXT;

-- meal_type için index ekle (performans için)
CREATE INDEX IF NOT EXISTS idx_meals_history_meal_type 
ON meals_history(user_id, date, meal_type);


