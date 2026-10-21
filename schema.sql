-- =====================================================
-- AI-Based Plant Disease Detection and Database Management
-- File: database/schema.sql
-- =====================================================

DROP DATABASE IF EXISTS plant_disease_db;
CREATE DATABASE plant_disease_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE plant_disease_db;

-- 1. Users: যারা সিস্টেম ব্যবহার করবে
CREATE TABLE users (
    user_id       INT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role          ENUM('farmer', 'admin') NOT NULL DEFAULT 'farmer',
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Plants: গাছের তালিকা
CREATE TABLE plants (
    plant_id   INT AUTO_INCREMENT PRIMARY KEY,
    plant_name VARCHAR(100) NOT NULL UNIQUE
);

-- 3. Diseases: রোগের তথ্য (প্রতিটি রোগ একটি গাছের সাথে যুক্ত)
CREATE TABLE diseases (
    disease_id   INT AUTO_INCREMENT PRIMARY KEY,
    plant_id     INT NOT NULL,
    disease_name VARCHAR(150) NOT NULL,
    symptoms     TEXT,
    treatment    TEXT,
    prevention   TEXT,
    FOREIGN KEY (plant_id) REFERENCES plants(plant_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 4. Images: ইউজারের আপলোড করা ছবি
CREATE TABLE images (
    image_id    INT AUTO_INCREMENT PRIMARY KEY,
    user_id     INT NOT NULL,
    image_path  VARCHAR(255) NOT NULL,
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 5. Predictions: AI-এর দেওয়া ফলাফল
CREATE TABLE predictions (
    prediction_id INT AUTO_INCREMENT PRIMARY KEY,
    image_id      INT NOT NULL,
    disease_id    INT NOT NULL,
    confidence    DECIMAL(5,2) NOT NULL,   -- শতাংশে, যেমন 97.50
    predicted_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (image_id) REFERENCES images(image_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (disease_id) REFERENCES diseases(disease_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- =====================================================
-- স্যাম্পল ডেটা
-- =====================================================

INSERT INTO users (name, email, password_hash, role) VALUES
('Admin User',  'admin@example.com',  'hashed_password_1', 'admin'),
('Rahim Uddin', 'rahim@example.com',  'hashed_password_2', 'farmer'),
('Karim Mia',   'karim@example.com',  'hashed_password_3', 'farmer');

INSERT INTO plants (plant_name) VALUES
('Tomato'),
('Potato'),
('Corn'),
('Apple');

INSERT INTO diseases (plant_id, disease_name, symptoms, treatment, prevention) VALUES
(1, 'Tomato Early Blight',
    'পাতায় বৃত্তাকার বাদামি দাগ, দাগের ভেতরে চক্রের মতো রেখা।',
    'আক্রান্ত পাতা কেটে ফেলুন এবং অনুমোদিত ছত্রাকনাশক স্প্রে করুন।',
    'ফসল পর্যায়ক্রমে চাষ করুন এবং গাছের গোড়ায় পানি দিন, পাতায় নয়।'),
(1, 'Tomato Late Blight',
    'পাতায় ও ফলে পানিভেজা কালচে দাগ, আর্দ্র আবহাওয়ায় দ্রুত ছড়ায়।',
    'আক্রান্ত গাছ তুলে ফেলুন এবং ছত্রাকনাশক ব্যবহার করুন।',
    'গাছের মাঝে পর্যাপ্ত ফাঁক রাখুন এবং জমিতে পানি জমতে দেবেন না।'),
(1, 'Tomato Healthy',
    'কোনো রোগের লক্ষণ নেই।',
    'চিকিৎসার প্রয়োজন নেই।',
    'নিয়মিত যত্ন ও পর্যবেক্ষণ করুন।'),
(2, 'Potato Early Blight',
    'নিচের পাতায় গাঢ় বাদামি দাগ, পরে পাতা হলুদ হয়ে ঝরে যায়।',
    'ছত্রাকনাশক স্প্রে করুন এবং আক্রান্ত পাতা সরিয়ে ফেলুন।',
    'রোগমুক্ত বীজ ব্যবহার করুন এবং সুষম সার দিন।'),
(2, 'Potato Late Blight',
    'পাতায় অনিয়মিত কালচে দাগ, নিচে সাদা ছত্রাকের আস্তরণ।',
    'দ্রুত ছত্রাকনাশক প্রয়োগ করুন, আক্রান্ত অংশ পুড়িয়ে ফেলুন।',
    'প্রতিরোধী জাত লাগান এবং জমির নিষ্কাশন ভালো রাখুন।'),
(3, 'Corn Common Rust',
    'পাতার দুই পাশে ছোট লালচে-বাদামি ফুসকুড়ি।',
    'প্রয়োজনে ছত্রাকনাশক ব্যবহার করুন।',
    'প্রতিরোধী জাত লাগান।'),
(4, 'Apple Scab',
    'পাতায় জলপাই-সবুজ থেকে কালচে দাগ, ফলে খসখসে ক্ষত।',
    'ছত্রাকনাশক স্প্রে করুন এবং ঝরা পাতা পরিষ্কার করুন।',
    'গাছের ডালপালা ছাঁটাই করে বাতাস চলাচলের ব্যবস্থা রাখুন।');

INSERT INTO images (user_id, image_path) VALUES
(2, 'uploads/tomato_leaf_001.jpg'),
(2, 'uploads/potato_leaf_002.jpg'),
(3, 'uploads/tomato_leaf_003.jpg');

INSERT INTO predictions (image_id, disease_id, confidence) VALUES
(1, 1, 96.40),
(2, 5, 91.25),
(3, 3, 98.80);
