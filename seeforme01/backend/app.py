from flask import Flask, request, jsonify
from flask_cors import CORS
import os
from PIL import Image
from io import BytesIO
from ultralytics import YOLO

app = Flask(__name__)
CORS(app)

# Load YOLOv5 model
model = YOLO('yolov5s.pt')  # It will download if not found

@app.route('/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    file = request.files['file']
    image = Image.open(file.stream).convert('RGB')

    results = model(image)

    detections = results[0].boxes.data.cpu().numpy() if results else []
    objects = set()
    if results and results[0].names:
        for box in results[0].boxes.data.cpu().numpy():
            objects.add(results[0].names[int(box[5])])

    objects = list(objects)
    caption = f"{len(objects)} பொருள்(கள்) கண்டறியப்பட்டது."

    return jsonify({
        "objects": objects,
        "caption": caption
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
