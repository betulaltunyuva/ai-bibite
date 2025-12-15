-- Profiles tablosu için RLS politikaları

-- 1. INSERT politikası: Kullanıcılar kendi profillerini oluşturabilir
CREATE POLICY "Users can insert their own profile"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- 2. SELECT politikası: Kullanıcılar kendi profillerini görebilir
CREATE POLICY "Users can view their own profile"
ON profiles FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- 3. UPDATE politikası: Kullanıcılar kendi profillerini güncelleyebilir
CREATE POLICY "Users can update their own profile"
ON profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 4. DELETE politikası (opsiyonel): Kullanıcılar kendi profillerini silebilir
CREATE POLICY "Users can delete their own profile"
ON profiles FOR DELETE
TO authenticated
USING (auth.uid() = id);


