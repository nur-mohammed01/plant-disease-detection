import json
import os
import re
import uuid

import mysql.connector
import numpy as np
from flask import Flask, render_template, request, send_from_directory
from PIL import Image
from tensorflow import keras

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_DIR = os.path.join(BASE_DIR, "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)

# XAMPP-এর ডিফল্ট সেটিং: ইউজার root, পাসওয়ার্ড নেই
DB_CONFIG = {
    "host": "127.0.0.1",
    "user": "root",
    "password": "",
    "database": "plant_disease_db",
}

ALLOWED_EXTENSIONS = {"jpg", "jpeg", "jfif", "png", "webp"}
LOW_CONFIDENCE = 70.0  # এর নিচে হলে "অনিশ্চিত" সতর্কতা দেখাবে

DB_ERROR = "ডাটাবেসে সংযোগ হয়নি। XAMPP-এ MySQL চালু আছে কিনা দেখুন।"

print("মডেল লোড হচ্ছে...")
model = keras.models.load_model(os.path.join(BASE_DIR, "model", "plant_model.keras"))
with open(os.path.join(BASE_DIR, "model", "class_names.json")) as f:
    class_names = json.load(f)
print("মডেল তৈরি।")

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = 8 * 1024 * 1024  # সর্বোচ্চ ৮ MB


def get_db():
    return mysql.connector.connect(**DB_CONFIG)


def split_class(class_name):
    """'Tomato___Early_blight' -> ('Tomato', 'Tomato Early blight')"""
    plant_raw, disease_raw = class_name.split("___")
    plant = re.sub(r"\(.*?\)", "", plant_raw)
    plant = plant.replace("_", " ").strip()
    disease = disease_raw.replace("_", " ").strip()
    if not disease.lower().startswith(plant.lower()):
        disease = f"{plant} {disease}"
    return plant, disease


def get_or_create_disease(cur, class_name):
    """প্লান্ট ও রোগ টেবিলে না থাকলে যোগ করে, disease_id ফেরত দেয়।"""
    plant, disease = split_class(class_name)

    cur.execute("SELECT plant_id FROM plants WHERE plant_name = %s", (plant,))
    row = cur.fetchone()
    if row:
        plant_id = row[0]
    else:
        cur.execute("INSERT INTO plants (plant_name) VALUES (%s)", (plant,))
        plant_id = cur.lastrowid

    cur.execute(
        "SELECT disease_id FROM diseases WHERE plant_id = %s AND disease_name = %s",
        (plant_id, disease),
    )
    row = cur.fetchone()
    if row:
        return row[0]
    cur.execute(
        "INSERT INTO diseases (plant_id, disease_name) VALUES (%s, %s)",
        (plant_id, disease),
    )
    return cur.lastrowid


def predict(path):
    img = Image.open(path).convert("RGB").resize((224, 224))
    arr = np.expand_dims(np.array(img, dtype="float32"), axis=0)
    probs = model.predict(arr, verbose=0)[0]
    i = int(np.argmax(probs))
    return class_names[i], float(probs[i]) * 100


def load_users():
    conn = get_db()
    try:
        cur = conn.cursor()
        cur.execute("SELECT user_id, name FROM users ORDER BY name")
        return cur.fetchall()
    finally:
        conn.close()


@app.route("/")
def index():
    try:
        users = load_users()
    except mysql.connector.Error:
        return render_template("index.html", users=[], result=None, error=DB_ERROR)
    return render_template("index.html", users=users, result=None, error=None)


@app.route("/predict", methods=["POST"])
def predict_route():
    try:
        users = load_users()
    except mysql.connector.Error:
        return render_template("index.html", users=[], result=None, error=DB_ERROR)

    def fail(message):
        return render_template("index.html", users=users, result=None, error=message)

    file = request.files.get("photo")
    user_id = request.form.get("user_id", type=int)

    if not file or file.filename == "":
        return fail("ছবি বাছাই করা হয়নি। একটি পাতার ছবি বেছে নিন।")
    ext = file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else ""
    if ext not in ALLOWED_EXTENSIONS:
        return fail("শুধু jpg, jpeg, jfif, png বা webp ছবি দেওয়া যাবে।")
    if user_id not in [u[0] for u in users]:
        return fail("তালিকা থেকে একজন ইউজার বেছে নিন।")

    filename = f"{uuid.uuid4().hex}.{ext}"
    path = os.path.join(UPLOAD_DIR, filename)
    file.save(path)

    try:
        class_name, confidence = predict(path)
    except Exception:
        os.remove(path)
        return fail("ছবিটি পড়া যায়নি। অন্য একটি ছবি দিয়ে চেষ্টা করুন।")

    conn = get_db()
    try:
        cur = conn.cursor()
        disease_id = get_or_create_disease(cur, class_name)
        cur.execute(
            "INSERT INTO images (user_id, image_path) VALUES (%s, %s)",
            (user_id, f"uploads/{filename}"),
        )
        image_id = cur.lastrowid
        cur.execute(
            "INSERT INTO predictions (image_id, disease_id, confidence) "
            "VALUES (%s, %s, %s)",
            (image_id, disease_id, round(confidence, 2)),
        )
        cur.execute(
            "SELECT disease_name, symptoms, treatment, prevention "
            "FROM diseases WHERE disease_id = %s",
            (disease_id,),
        )
        disease = cur.fetchone()
        conn.commit()
    except mysql.connector.Error:
        conn.rollback()
        return fail(DB_ERROR)
    finally:
        conn.close()

    result = {
        "filename": filename,
        "disease_name": disease[0],
        "symptoms": disease[1],
        "treatment": disease[2],
        "prevention": disease[3],
        "confidence": confidence,
        "uncertain": confidence < LOW_CONFIDENCE,
    }
    return render_template("index.html", users=users, result=result, error=None)


@app.route("/history")
def history():
    try:
        conn = get_db()
    except mysql.connector.Error:
        return render_template("history.html", rows=[], error=DB_ERROR)
    try:
        cur = conn.cursor()
        cur.execute(
            "SELECT pr.predicted_at, u.name, i.image_path, d.disease_name, pr.confidence "
            "FROM predictions pr "
            "JOIN images i ON pr.image_id = i.image_id "
            "JOIN users u ON i.user_id = u.user_id "
            "JOIN diseases d ON pr.disease_id = d.disease_id "
            "ORDER BY pr.predicted_at DESC LIMIT 50"
        )
        rows = cur.fetchall()
    finally:
        conn.close()
    return render_template("history.html", rows=rows, error=None)


@app.route("/uploads/<name>")
def uploaded_file(name):
    return send_from_directory(UPLOAD_DIR, name)


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=False)
