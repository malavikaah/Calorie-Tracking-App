import tensorflow as tf

def check_model(path):
    try:
        interpreter = tf.lite.Interpreter(model_path=path)
        interpreter.allocate_tensors()
        
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print(f"Model: {path}")
        print(f"Input Shape: {input_details[0]['shape']}")
        print(f"Output Shape: {output_details[0]['shape']}")
    except Exception as e:
        print(f"Error checking {path}: {e}")

check_model('assets/model/food_model.tflite')
check_model('assets/model/best_float32.tflite')
