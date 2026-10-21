-- =====================================================
-- File: database/queries.sql
-- প্রতিটি কুয়েরি আলাদা আলাদা করে চালাবেন
-- =====================================================

USE plant_disease_db;

-- কুয়েরি ১: সব রোগ, গাছের নামসহ (JOIN)
SELECT p.plant_name, d.disease_name, d.symptoms
FROM diseases d
JOIN plants p ON d.plant_id = p.plant_id
ORDER BY p.plant_name;

-- কুয়েরি ২: প্রেডিকশনের পূর্ণ ইতিহাস (৪টা টেবিল JOIN)
SELECT u.name AS user_name,
       i.image_path,
       pl.plant_name,
       d.disease_name,
       pr.confidence,
       pr.predicted_at
FROM predictions pr
JOIN images   i  ON pr.image_id   = i.image_id
JOIN users    u  ON i.user_id     = u.user_id
JOIN diseases d  ON pr.disease_id = d.disease_id
JOIN plants   pl ON d.plant_id    = pl.plant_id
ORDER BY pr.predicted_at DESC;

-- কুয়েরি ৩: কোন রোগ কতবার ধরা পড়েছে (GROUP BY)
SELECT d.disease_name, COUNT(*) AS total_detected
FROM predictions pr
JOIN diseases d ON pr.disease_id = d.disease_id
GROUP BY d.disease_name
ORDER BY total_detected DESC;

-- কুয়েরি ৪: প্রতিটি গাছের গড় কনফিডেন্স (AVG)
SELECT pl.plant_name, ROUND(AVG(pr.confidence), 2) AS avg_confidence
FROM predictions pr
JOIN diseases d  ON pr.disease_id = d.disease_id
JOIN plants   pl ON d.plant_id    = pl.plant_id
GROUP BY pl.plant_name;

-- কুয়েরি ৫: প্রতিটি ইউজার কতগুলো ছবি আপলোড করেছে
SELECT u.name, COUNT(i.image_id) AS total_images
FROM users u
LEFT JOIN images i ON u.user_id = i.user_id
GROUP BY u.name;

-- কুয়েরি ৬: যেসব রোগ এখনো একবারও ধরা পড়েনি (LEFT JOIN)
SELECT d.disease_name
FROM diseases d
LEFT JOIN predictions pr ON d.disease_id = pr.disease_id
WHERE pr.prediction_id IS NULL;

-- কুয়েরি ৭: ৯০% এর বেশি কনফিডেন্সের প্রেডিকশন, চিকিৎসাসহ
SELECT d.disease_name, pr.confidence, d.treatment
FROM predictions pr
JOIN diseases d ON pr.disease_id = d.disease_id
WHERE pr.confidence > 90;
