import tensorflow as tf
import os

model_input = 'pneumonia_model.h5' 
model_output = 'pneumonia_model.tflite'

if not os.path.exists(model_input):
    print(f"HATA: {model_input} hala bulunamadı!")
else:
    print("Model yükleniyor ve TFLite'a dönüştürülüyor...")
    model = tf.keras.models.load_model(model_input)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    #PythonAnywhere uyumluluğu çin
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS, 
        tf.lite.OpsSet.SELECT_TF_OPS
    ]
    
    tflite_model = converter.convert()
    with open(model_output, 'wb') as f:
        f.write(tflite_model)
    print(f"BAŞARILI! Yeni dosya: {model_output}")