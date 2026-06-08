from abc import ABC, abstractmethod


class BaseModel(ABC):
    @abstractmethod
    def load(self) -> None:
        """Load model weights and supporting data files."""

    @abstractmethod
    def predict(self, image_path: str) -> dict:
        """Run inference and return a standardised result dict."""

    @property
    @abstractmethod
    def name(self) -> str:
        """Short identifier: 'keras' or 'tflite'."""

    @property
    @abstractmethod
    def classes(self) -> list:
        """List of class label strings this model outputs."""
