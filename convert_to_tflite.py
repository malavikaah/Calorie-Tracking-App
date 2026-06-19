import os
import sys
import tensorflow as tf

# --- THE SUPER PATCH ---
print("Applying Super Patch for TensorFlow compatibility...")
try:
    # Force load the internal module and inject the missing attribute
    import tensorflow._api.v2.compat.v2.__internal__ as tf_internal
    tf_internal.register_load_context_function = lambda x: None
    print("-> Successfully patched internal module.")
except Exception as e:
    print(f"-> Patch warning: {e}")

# Also patch the standard reference
try:
    tf.__internal__.register_load_context_function = lambda x: None
except:
    pass
# ---------------------

# Now import the tool
try:
    from onnx2tf import convert
except ImportError:
    print("Error: onnx2tf not found. Please run 'pip install onnx2tf'")
    sys.exit(1)

def run_conversion():
    onnx_path = r'C:\projects\calory tracking app\runs\detect\train-2\weights\best.onnx'
    output_dir = r'C:\projects\calory tracking app\assets\model'

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    print(f"Converting {onnx_path} to TFLite...")

    try:
        # Run conversion
        convert(
            input_onnx_file_path=onnx_path,
            output_folder_path=output_dir,
            not_use_onnxsim=True
        )
        print("\nSUCCESS! Your model should now be in the 'assets/model' folder.")
    except Exception as e:
        print(f"\nError during conversion: {e}")

if __name__ == "__main__":
    run_conversion()
