import sys
import json
import numpy as np
from PIL import Image
from tensorflow import keras

MODEL_PATH = "model/plant_model.keras"
CLASS_PATH = "model/class_names.json"

if len(sys.argv) < 2:
    print("ব্যবহার: python predict_test.py ছবির_নাম.jpg")
    sys.exit(1)

model = keras.models.load_model(MODEL_PATH)
with open(CLASS_PATH) as f:
    class_names = json.load(f)

img = Image.open(sys.argv[1]).convert("RGB").resize((224, 224))
arr = np.expand_dims(np.array(img, dtype="float32"), axis=0)

probs = model.predict(arr)[0]
top3 = np.argsort(probs)[::-1][:3]

print()
print("সবচেয়ে সম্ভাব্য ৩টি ফলাফল:")
for i in top3:
    print(f"  {class_names[i]}: {probs[i] * 100:.2f}%")
