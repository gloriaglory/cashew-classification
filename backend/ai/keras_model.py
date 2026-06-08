import json
import numpy as np
from PIL import Image
from django.conf import settings
from .base import BaseModel


class KerasModel(BaseModel):
    def __init__(self):
        self._model = None
        self._disease_info = None
        self._pesticide_info = None

    @property
    def name(self):
        return 'keras'

    @property
    def classes(self):
        return self._disease_info.get('classes', []) if self._disease_info else []

    def load(self):
        model_path = settings.AI_MODEL_DIR / 'cashew_nut_disease_model.keras'
        if not model_path.exists():
            raise FileNotFoundError(f"Keras model not found at {model_path}. Place it in backend/models/")
        try:
            import keras
            self._model = keras.models.load_model(str(model_path))
        except Exception:
            import tensorflow as tf
            self._model = tf.keras.models.load_model(str(model_path))

        with open(settings.AI_DATA_DIR / 'disease_info.json', encoding='utf-8') as f:
            self._disease_info = json.load(f)
        with open(settings.AI_DATA_DIR / 'pesticide_recommendations.json', encoding='utf-8') as f:
            self._pesticide_info = json.load(f)

    def predict(self, image_path: str) -> dict:
        import tensorflow as tf
        size = getattr(settings, 'IMAGE_SIZE', (224, 224))

        img = Image.open(image_path).convert('RGB').resize(size, Image.LANCZOS)
        arr = np.expand_dims(np.array(img, dtype=np.float32) / 255.0, axis=0)

        raw = self._model.predict(arr, verbose=0)
        probs = tf.nn.softmax(raw[0]).numpy()

        class_names = self._disease_info['classes']
        idx = int(np.argmax(probs))
        pred_class = class_names[idx]
        confidence = float(probs[idx]) * 100

        disease_info = self._disease_info['diseases'].get(pred_class, {})
        pesticide_info = self._pesticide_info.get(pred_class, {})

        return {
            'disease_name': pred_class.replace('_', ' '),
            'class_key': pred_class,
            'confidence': round(confidence, 2),
            'is_healthy': pred_class == 'Healthy',
            'description': disease_info.get('description', ''),
            'symptoms': disease_info.get('symptoms', ''),
            'prevention': disease_info.get('prevention', ''),
            'pesticide_name': pesticide_info.get('pesticide_name', 'N/A'),
            'dosage': pesticide_info.get('dosage', 'N/A'),
            'application_method': pesticide_info.get('application_method', 'N/A'),
            'recommendation': pesticide_info.get('recommendation', 'N/A'),
            'all_probabilities': {
                class_names[i].replace('_', ' '): round(float(probs[i]) * 100, 2)
                for i in range(len(class_names))
            },
            'model_used': 'keras',
        }
