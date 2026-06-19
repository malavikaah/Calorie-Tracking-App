import os
import shutil
import tensorflow as tf
from tensorflow.keras.preprocessing import image_dataset_from_directory
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras import layers, models

# ==========================================
# 1. SETUP & PATHS
# ==========================================
# Targeting a single dataset for faster training
BASE_DATASET_DIR = r"C:\Users\VICTUS\OneDrive\Desktop\dataset\food_data\Indian Food Images"

# We will copy all images to a unified dataset folder to train effectively
UNIFIED_DATASET_DIR = r"C:\Users\VICTUS\OneDrive\Desktop\dataset\unified_indian_food_data"
MODEL_SAVE_PATH = os.path.join(os.getcwd(), 'assets', 'model', 'food_model.tflite')
LABELS_SAVE_PATH = os.path.join(os.getcwd(), 'assets', 'model', 'labels.txt')

IMG_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS = 10  # Increase epochs for better accuracy

def unify_datasets():
    print("Step 1: Unifying datasets into a single folder...")
    if not os.path.exists(UNIFIED_DATASET_DIR):
        os.makedirs(UNIFIED_DATASET_DIR)
    
    # We deeply search for class folders
    for root, dirs, files in os.walk(BASE_DATASET_DIR):
        # A folder is considered a "class folder" if it has image files directly in it
        has_images = any(f.lower().endswith(('.png', '.jpg', '.jpeg')) for f in files)
        
        if has_images:
            class_name = os.path.basename(root).lower().replace('_', ' ').title()
            dest_class_dir = os.path.join(UNIFIED_DATASET_DIR, class_name)
            
            if not os.path.exists(dest_class_dir):
                os.makedirs(dest_class_dir)
            
            for f in files:
                if f.lower().endswith(('.png', '.jpg', '.jpeg')):
                    src_file = os.path.join(root, f)
                    dest_file = os.path.join(dest_class_dir, f)
                    if not os.path.exists(dest_file):
                        try:
                            shutil.copy2(src_file, dest_file)
                        except Exception as e:
                            pass
    print(f"Dataset completely unified at: {UNIFIED_DATASET_DIR}")

def train_and_convert():
    print("\nStep 2: Loading images into TensorFlow...")
    
    # Load Training Data
    train_dataset = image_dataset_from_directory(
        UNIFIED_DATASET_DIR,
        validation_split=0.2,
        subset="training",
        seed=123,
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE
    )

    # Load Validation Data
    validation_dataset = image_dataset_from_directory(
        UNIFIED_DATASET_DIR,
        validation_split=0.2,
        subset="validation",
        seed=123,
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE
    )

    class_names = train_dataset.class_names
    print(f"Found {len(class_names)} food classes: {class_names}")
    
    # Save labels to text file for Flutter
    with open(LABELS_SAVE_PATH, 'w') as f:
        f.write('\n'.join(class_names))
    print(f"Labels saved to {LABELS_SAVE_PATH}")

    # Optimize datasets for performance
    AUTOTUNE = tf.data.AUTOTUNE
    train_dataset = train_dataset.prefetch(buffer_size=AUTOTUNE)
    validation_dataset = validation_dataset.prefetch(buffer_size=AUTOTUNE)

    print("\nStep 3: Building and Compiling the Model (MobileNetV2)...")
    # Base model using MobileNetV2 (Extremely lightweight, great for Flutter apps)
    base_model = MobileNetV2(input_shape=IMG_SIZE + (3,), include_top=False, weights='imagenet')
    base_model.trainable = False  # Freeze base model

    # Add custom fully connected layers on top specifically for our food
    model = models.Sequential([
        layers.Rescaling(1./127.5, offset=-1, input_shape=IMG_SIZE + (3,)), # Preprocessing for MobileNet
        base_model,
        layers.GlobalAveragePooling2D(),
        layers.Dropout(0.2),
        layers.Dense(len(class_names), activation='softmax')
    ])

    model.compile(optimizer='adam',
                  loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=False),
                  metrics=['accuracy'])

    print("\nStep 4: Training the Model (This might take a while!)...")
    history = model.fit(
        train_dataset,
        validation_data=validation_dataset,
        epochs=EPOCHS
    )

    print("\nStep 5: Converting the trained model to TensorFlow Lite (.tflite) format...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()

    with open(MODEL_SAVE_PATH, 'wb') as f:
        f.write(tflite_model)
    
    print(f"\nSUCCESS! Your TFLite model is saved at: {MODEL_SAVE_PATH}")
    print("You can now move 'food_model.tflite' and 'labels.txt' into your Flutter app's assets/model/ directory.")

if __name__ == "__main__":
    print("=== HYBRID FOOD MODEL TRAINING SCRIPT ===")
    
    # Optional: Run unify_datasets() to automatically combine your 4 folders
    # If it's already perfectly unified, comment this out.
    unify_datasets()
    
    # Train the model and export for Flutter
    train_and_convert()
