-- Profiles tablosuna gerekli kolonları ekle
-- Eğer kolonlar zaten varsa hata vermez (IF NOT EXISTS benzeri davranış)

-- Cinsiyet
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS gender TEXT;

-- Doğum Yılı
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS birth_year INTEGER;

-- Boy (cm)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS height DOUBLE PRECISION;

-- Kilo (kg)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS weight DOUBLE PRECISION;

-- Hedef
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS goal TEXT;

-- Aktivite Düzeyi
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS activity_level TEXT;

-- Alerjiler
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS allergies TEXT;

-- Hastalıklar
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS diseases TEXT;

-- Diyet Tipi
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS diet_type TEXT;

-- Güncelleme Tarihi
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE;


