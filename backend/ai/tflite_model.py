import json
import numpy as np
from PIL import Image
from django.conf import settings
from .base import BaseModel

_LABELS = ['anthracnose', 'gumosis', 'healthy', 'leaf_miner', 'red_rust']

# Map TFLite labels to the keys used in pesticide_recommendations.json / disease_info.json
_LABEL_TO_KEY = {
    'anthracnose': 'Anthracnose',
    'gumosis':     'Gummosis',
    'healthy':     'Healthy',
    'leaf_miner':  'Leaf_Blight',
    'red_rust':    'Die_Back',
}


class TFLiteModel(BaseModel):
    def __init__(self):
        self._interpreter = None
        self._recommendations = None

    @property
    def name(self):
        return 'tflite'

    @property
    def classes(self):
        return list(_LABELS)

    def load(self):
        model_path = settings.AI_MODEL_DIR / 'cashew_model.tflite'
        if not model_path.exists():
            raise FileNotFoundError(f"TFLite model not found at {model_path}. Place it in backend/models/")

        try:
            import tflite_runtime.interpreter as tflite
            self._interpreter = tflite.Interpreter(model_path=str(model_path))
        except ImportError:
            import tensorflow as tf
            self._interpreter = tf.lite.Interpreter(model_path=str(model_path))

        self._interpreter.allocate_tensors()

        rec_path = settings.AI_DATA_DIR / 'pesticide_recommendations.json'
        with open(rec_path, encoding='utf-8') as f:
            self._recommendations = json.load(f)

    def predict(self, image_path: str) -> dict:
        size = getattr(settings, 'IMAGE_SIZE', (224, 224))
        img = Image.open(image_path).convert('RGB').resize(size, Image.LANCZOS)
        arr = np.expand_dims(np.array(img, dtype=np.float32), axis=0)

        inp = self._interpreter.get_input_details()
        out = self._interpreter.get_output_details()
        self._interpreter.set_tensor(inp[0]['index'], arr)
        self._interpreter.invoke()
        probs = self._interpreter.get_tensor(out[0]['index'])[0]

        idx = int(np.argmax(probs))
        label = _LABELS[idx]
        confidence = float(probs[idx]) * 100
        json_key = _LABEL_TO_KEY.get(label, label.title())
        rec = self._recommendations.get(json_key, {})

        return {
            'disease_name': json_key.replace('_', ' '),
            'class_key': label,
            'confidence': round(confidence, 2),
            'is_healthy': label == 'healthy',
            'description': rec.get('recommendation', ''),
            'symptoms': rec.get('recommendation', ''),
            'prevention': rec.get('recommendation', ''),
            'pesticide_name': rec.get('pesticide_name', 'N/A'),
            'dosage': rec.get('dosage', 'N/A'),
            'application_method': rec.get('application_method', 'N/A'),
            'recommendation': rec.get('recommendation', 'N/A'),
            'all_probabilities': {
                _LABEL_TO_KEY.get(_LABELS[i], _LABELS[i]): round(float(probs[i]) * 100, 2)
                for i in range(len(_LABELS))
            },
            'model_used': 'tflite',
        }
