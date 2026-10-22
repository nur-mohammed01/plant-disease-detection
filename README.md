# AI-Based Plant Disease Detection and Database Management

A database-driven web application that identifies plant leaf diseases from a photo using a deep learning model, and stores users, images, diseases and predictions in a MySQL database.

## Features

- Upload a leaf photo and get the predicted disease with a confidence score
- Disease information (symptoms, treatment, prevention) loaded from the database
- Every upload and prediction is saved in MySQL
- History page listing past predictions (SQL JOIN across four tables)
- Warning shown when the model's confidence is below 70%

## Tech stack

| Part | Tool |
|---|---|
| Model | TensorFlow / Keras, MobileNetV2 (transfer learning) |
| Training | Google Colab (T4 GPU) |
| Dataset | PlantVillage (38 classes, 54,305 images) via Kaggle |
| Database | MySQL (XAMPP + phpMyAdmin) |
| Web app | Python, Flask |

## Database design

Five tables: `users`, `plants`, `diseases`, `images`, `predictions`, linked with foreign keys.

- `schema.sql` creates the database, tables and sample data
- `queries.sql` contains 7 example queries (JOIN, GROUP BY, AVG, LEFT JOIN, filtering)

## Model results

MobileNetV2 (ImageNet weights, frozen base) with a new classification head, trained for 5 epochs.

| Metric | Value |
|---|---|
| Training accuracy | 94.35% |
| Validation accuracy | 94.51% |
| Train / validation split | 80% / 20% (43,444 / 10,861 images) |

## Limitations

PlantVillage images are taken in a lab: one leaf, plain background, even lighting. The model scores about 94.5% on that kind of image, but it can be wrong on photos taken in the field, with busy backgrounds, several leaves, or fruit instead of a leaf. In our own test with one such tomato leaf photo, the model predicted the wrong disease with 75.6% confidence, so the confidence score alone should not be trusted on photos unlike the training data.

Possible future work: fine-tune on field photos, add user login, and fill in treatment information for all 38 classes.

## Project structure

```
app.py               Flask app (model + database)
requirements.txt     Python packages
predict_test.py      Test the model on one image from the command line
schema.sql           Database schema and sample data
queries.sql          Example SQL queries
templates/           HTML pages
model/               Trained model (plant_model.keras) and class_names.json
```

## How to run

1. Install Python 3.12 and XAMPP.
2. Start **MySQL** in the XAMPP Control Panel.
3. Open phpMyAdmin (`localhost/phpmyadmin`), go to **Import**, and import `schema.sql`.
4. Install the packages:
   ```
   pip install -r requirements.txt
   ```
5. Run the app:
   ```
   python app.py
   ```
6. Open `http://127.0.0.1:5000` in your browser.

The app connects to MySQL as `root` with an empty password (XAMPP default). Change `DB_CONFIG` in `app.py` if your setup is different.

## Credits

- PlantVillage dataset (Kaggle: abdallahalidev/plantvillage-dataset)
- MobileNetV2 architecture and ImageNet weights via Keras Applications
