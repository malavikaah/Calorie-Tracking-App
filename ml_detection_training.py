from ultralytics import YOLO
import os
import torch

def train_detection_model():
    print("Loading base YOLOv8n model...")
    model = YOLO('yolov8n.pt') 

    # Automatically check if GPU is available
    device = 0 if torch.cuda.is_available() else 'cpu'
    print(f"Using device: {device}")

    print("\nStarting FAST training on 20 Indian Food classes...")
    results = model.train(
        data='food_detection.yaml',
        epochs=10,        # Reduced to 10 for speed
        imgsz=320,        # Reduced to 320 to make it 4x faster
        plots=True,
        device=device
    )

    print("\nTraining complete! Exporting to TFLite...")
    model.export(format='tflite', imgsz=320) # Must match training size

    print("\nSUCCESS!")
    print("Check the 'runs/detect/train/weights/' folder.")

if __name__ == "__main__":
    train_detection_model()
