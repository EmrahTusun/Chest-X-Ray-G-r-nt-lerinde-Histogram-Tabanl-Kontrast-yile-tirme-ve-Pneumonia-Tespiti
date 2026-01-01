import os
import cv2
import numpy as np
import base64
from flask import Flask, request, jsonify
from flask_cors import CORS
import tflite_runtime.interpreter as tflite
from image_processing import apply_hist_eq, apply_clahe

app = Flask(__name__)
CORS(app)

BASE_DIR = "/home/hsherlock/mysite"
MODEL_PATH = os.path.join(BASE_DIR, "pneumonia_model.tflite")

interpreter = tflite.Interpreter(model_path=MODEL_PATH)
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

def calculate_metrics_simple(original, processed):
    # PSNR Hesaplama
    mse = np.mean((original - processed) ** 2)
    if mse == 0:
        p_val = 100
    else:
        p_val = round(20 * np.log10(255.0 / np.sqrt(mse)), 2)

    # SSIM Hesaplama
    res = cv2.matchTemplate(original, processed, cv2.TM_CCOEFF_NORMED)[0][0]
    s_val = round(float(res), 4)

    return p_val, s_val

def predict_tflite(img):
    img_res = cv2.resize(img, (224, 224))
    if len(img_res.shape) == 2:
        img_res = cv2.cvtColor(img_res, cv2.COLOR_GRAY2RGB)
    img_array = np.expand_dims(img_res / 255.0, axis=0).astype(np.float32)
    interpreter.set_tensor(input_details[0]['index'], img_array)
    interpreter.invoke()
    prediction = interpreter.get_tensor(output_details[0]['index'])[0][0]
    return round(float(prediction) * 100, 2)

def encode_img_to_base64(img):
    _, buffer = cv2.imencode('.jpg', img)
    return base64.b64encode(buffer).decode('utf-8')

@app.route('/analyze', methods=['POST'])
def analyze():
    file = request.files['image'].read()
    npimg = np.frombuffer(file, np.uint8)
    img = cv2.imdecode(npimg, cv2.IMREAD_COLOR)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    res_orig = predict_tflite(img)

    # Histogram
    hist_img = apply_hist_eq(gray)
    h_psnr, h_ssim = calculate_metrics_simple(gray, hist_img)
    res_hist = predict_tflite(cv2.cvtColor(hist_img, cv2.COLOR_GRAY2RGB))

    # CLAHE
    clahe_img = apply_clahe(gray)
    c_psnr, c_ssim = calculate_metrics_simple(gray, clahe_img)
    res_clahe = predict_tflite(cv2.cvtColor(clahe_img, cv2.COLOR_GRAY2RGB))

    return jsonify({
        "original_score": res_orig,
        "hist_score": res_hist,
        "hist_psnr": h_psnr,
        "hist_ssim": h_ssim,
        "clahe_score": res_clahe,
        "clahe_psnr": c_psnr,
        "clahe_ssim": c_ssim,
        "hist_img_base64": encode_img_to_base64(hist_img),
        "clahe_img_base64": encode_img_to_base64(clahe_img)
    })