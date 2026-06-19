from ultralytics import YOLO
import os

def train_new_dataset():
    # Load the base model (YOLOv8n)
    model = YOLO('yolov8n.pt') 
    
    print("Starting training on Archive (1) dataset...")
    
    # Start training
    results = model.train(
        data='archive_training.yaml',
        epochs=30, # 30 epochs for a solid update
        imgsz=320,
        batch=16,
        name='archive_1_run'
    )
    
    print("Training complete!")
    print(f"Model saved at: {results.save_dir}")
    
    # Export to TFLite for Flutter
    print("Exporting to TFLite...")
    model.export(format='tflite', imgsz=320)
    print("Export complete!")

if __name__ == "__main__":
    train_new_dataset()
