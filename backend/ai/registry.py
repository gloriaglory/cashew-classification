"""
Thread-safe AI model registry with runtime switching.

Active model is stored in SystemConfig DB ('active_model' key).
Falls back to settings.ACTIVE_AI_MODEL env var if DB is unavailable.

Usage:
    from ai.registry import get_model, switch_model

    result = get_model().predict(image_path)
    switch_model('tflite')   # hot-swap, no restart needed
"""
import threading
from django.conf import settings

_lock = threading.Lock()
_model = None
_model_type = None


def _active_model_type() -> str:
    try:
        from apps.detection.models import SystemConfig
        return SystemConfig.get('active_model', settings.ACTIVE_AI_MODEL)
    except Exception:
        return settings.ACTIVE_AI_MODEL


def get_model():
    global _model, _model_type
    wanted = _active_model_type()
    with _lock:
        if _model is None or _model_type != wanted:
            _model = _load(wanted)
            _model_type = wanted
    return _model


def switch_model(model_type: str) -> None:
    global _model, _model_type
    from apps.detection.models import SystemConfig
    SystemConfig.set('active_model', model_type)
    with _lock:
        _model = None
        _model_type = None


def _load(model_type: str):
    if model_type == 'tflite':
        from .tflite_model import TFLiteModel
        m = TFLiteModel()
    else:
        from .keras_model import KerasModel
        m = KerasModel()
    m.load()
    print(f"[AI] Loaded model: {model_type} | classes: {m.classes}")
    return m
