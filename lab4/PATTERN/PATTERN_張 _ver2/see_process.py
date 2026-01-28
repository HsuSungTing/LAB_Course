import numpy as np
import struct
from tabulate import tabulate

def binary_to_float(b):
    """Convert 32-bit binary string to float"""
    return struct.unpack('!f', int(b, 2).to_bytes(4, byteorder='big'))[0]

def replication_padding(img):
    """Apply replication padding with width=1"""
    h, w = img.shape
    padded = np.zeros((h+2, w+2))
    padded[1:-1, 1:-1] = img
    padded[0, 1:-1] = img[0, :]
    padded[-1, 1:-1] = img[-1, :]
    padded[1:-1, 0] = img[:, 0]
    padded[1:-1, -1] = img[:, -1]
    padded[0, 0] = img[0, 0]
    padded[0, -1] = img[0, -1]
    padded[-1, 0] = img[-1, 0]
    padded[-1, -1] = img[-1, -1]
    return padded

def reflection_padding(img):
    """Apply reflection padding with width=1"""
    h, w = img.shape
    padded = np.zeros((h+2, w+2))
    padded[1:-1, 1:-1] = img
    padded[0, 1:-1] = img[1, :]
    padded[-1, 1:-1] = img[-2, :]
    padded[1:-1, 0] = img[:, 1]
    padded[1:-1, -1] = img[:, -2]
    padded[0, 0] = img[1, 1]
    padded[0, -1] = img[1, -2]
    padded[-1, 0] = img[-2, 1]
    padded[-1, -1] = img[-2, -2]
    return padded

def convolution(img, kernel):
    """Perform 2D convolution"""
    h, w = img.shape
    kh, kw = kernel.shape
    output = np.zeros((h - kh + 1, w - kw + 1))
    for i in range(output.shape[0]):
        for j in range(output.shape[1]):
            output[i, j] = np.sum(img[i:i+kh, j:j+kw] * kernel)
    return output

def max_pooling(feature_map):
    """Perform 3x3 max pooling"""
    h, w = feature_map.shape
    output = np.zeros((h // 3, w // 3))
    for i in range(output.shape[0]):
        for j in range(output.shape[1]):
            output[i, j] = np.max(feature_map[i*3:(i+1)*3, j*3:(j+1)*3])
    return output

def tanh_activation(x):
    """Tanh activation function"""
    return np.tanh(x)

def swish_activation(x):
    """Swish activation function"""
    return x / (1 + np.exp(-x))

def leaky_relu(x, alpha=0.01):
    """Leaky ReLU activation"""
    return np.where(x >= 0, x, alpha * x)

def fully_connected(input_vec, weight, bias):
    """Fully connected layer"""
    return np.dot(weight, input_vec) + bias

def softmax(x):
    """Softmax function"""
    exp_x = np.exp(x - np.max(x))
    return exp_x / np.sum(exp_x)

def read_input_file(filename='input.txt'):
    """Read input.txt and parse patterns"""
    with open(filename, 'r') as f:
        lines = [line.strip() for line in f.readlines()]
    
    num_patterns = int(lines[0])
    patterns = []
    line_idx = 1
    
    for _ in range(num_patterns):
        task, mode = map(int, lines[line_idx].split())
        line_idx += 1
        
        if task == 0:
            # Read image (72 cycles for 6x6x2)
            image = np.zeros((2, 6, 6))
            for ch in range(2):
                for i in range(6):
                    for j in range(6):
                        image[ch][i][j] = binary_to_float(lines[line_idx])
                        line_idx += 1
            
            # Read kernels (18 cycles)
            kernel_ch1 = np.zeros((2, 3, 3))
            kernel_ch2 = np.zeros((2, 3, 3))
            for k in range(2):
                for i in range(3):
                    for j in range(3):
                        k1_bin, k2_bin = lines[line_idx].split()
                        kernel_ch1[k][i][j] = binary_to_float(k1_bin)
                        kernel_ch2[k][i][j] = binary_to_float(k2_bin)
                        line_idx += 1
            
            # Read weight_bias (57 cycles)
            weight1 = np.zeros((5, 8))
            weight2 = np.zeros((3, 5))
            bias1 = np.zeros(5)
            bias2 = np.zeros(3)
            
            # Weight1: 5x8 = 40 values
            for i in range(5):
                for j in range(8):
                    weight1[i][j] = binary_to_float(lines[line_idx])
                    line_idx += 1
            
            # Bias1: 1 value (repeated for all 5 neurons)
            bias1_val = binary_to_float(lines[line_idx])
            bias1[:] = bias1_val
            line_idx += 1
            
            # Weight2: 3x5 = 15 values
            for i in range(3):
                for j in range(5):
                    weight2[i][j] = binary_to_float(lines[line_idx])
                    line_idx += 1
            
            # Bias2: 1 value (repeated for all 3 neurons)
            bias2_val = binary_to_float(lines[line_idx])
            bias2[:] = bias2_val
            line_idx += 1
            
            patterns.append({
                'task': task,
                'mode': mode,
                'image': image,
                'kernel_ch1': kernel_ch1,
                'kernel_ch2': kernel_ch2,
                'weight1': weight1,
                'bias1': bias1,
                'weight2': weight2,
                'bias2': bias2
            })
            
        else:  # task == 1
            # Read image (36 cycles for 6x6x1)
            image = np.zeros((6, 6))
            for i in range(6):
                for j in range(6):
                    image[i][j] = binary_to_float(lines[line_idx])
                    line_idx += 1
            
            # Read kernels (18 cycles)
            kernel_a = np.zeros((3, 3))
            kernel_c = np.zeros((3, 3))
            kernel_b = np.zeros((3, 3))
            kernel_d = np.zeros((3, 3))
            
            for i in range(3):
                for j in range(3):
                    ka_bin, kc_bin = lines[line_idx].split()
                    kernel_a[i][j] = binary_to_float(ka_bin)
                    kernel_c[i][j] = binary_to_float(kc_bin)
                    line_idx += 1
            
            for i in range(3):
                for j in range(3):
                    kb_bin, kd_bin = lines[line_idx].split()
                    kernel_b[i][j] = binary_to_float(kb_bin)
                    kernel_d[i][j] = binary_to_float(kd_bin)
                    line_idx += 1
            
            patterns.append({
                'task': task,
                'mode': mode,
                'image': image,
                'kernels': [kernel_a, kernel_b, kernel_c, kernel_d]
            })
            
            # Skip capacity_cost (5 cycles)
            line_idx += 5
    
    return patterns

def visualize_convolution(pattern):
    """Visualize convolution process"""
    task = pattern['task']
    mode = pattern['mode']
    
    mode_names = {0: "Replication + Tanh", 1: "Replication + Swish", 
                  2: "Reflection + Tanh", 3: "Reflection + Swish"}
    
    print(f"\n{'='*80}")
    print(f"Task {task} | Mode {mode}: {mode_names[mode]}")
    print(f"{'='*80}\n")
    
    padding_func = replication_padding if mode in [0, 1] else reflection_padding
    activation_func = tanh_activation if mode in [0, 2] else swish_activation
    activation_name = "Tanh" if mode in [0, 2] else "Swish"
    
    if task == 0:
        # Show original images
        print("Original Image 0 (Channel 0):")
        print(tabulate(pattern['image'][0], tablefmt='rounded_grid', floatfmt='.4f'))
        print("\nOriginal Image 1 (Channel 1):")
        print(tabulate(pattern['image'][1], tablefmt='rounded_grid', floatfmt='.4f'))
        
        # Show padded images
        padded_0 = padding_func(pattern['image'][0])
        padded_1 = padding_func(pattern['image'][1])
        
        print(f"\nPadded Image 0 (8x8):")
        print(tabulate(padded_0, tablefmt='rounded_grid', floatfmt='.4f'))
        print(f"\nPadded Image 1 (8x8):")
        print(tabulate(padded_1, tablefmt='rounded_grid', floatfmt='.4f'))
        
        # Process Feature Map 0
        print("\n" + "="*80)
        print("Feature Map 0 = kernel_ch1[0] * img[0] + kernel_ch1[1] * img[1]")
        print("="*80)
        
        print("\nKernel_ch1[0]:")
        print(tabulate(pattern['kernel_ch1'][0], tablefmt='rounded_grid', floatfmt='.4f'))
        conv_ch1_0 = convolution(padded_0, pattern['kernel_ch1'][0])
        print("\nConv(kernel_ch1[0] * img[0]):")
        print(tabulate(conv_ch1_0, tablefmt='rounded_grid', floatfmt='.6f'))
        
        print("\nKernel_ch1[1]:")
        print(tabulate(pattern['kernel_ch1'][1], tablefmt='rounded_grid', floatfmt='.4f'))
        conv_ch1_1 = convolution(padded_1, pattern['kernel_ch1'][1])
        print("\nConv(kernel_ch1[1] * img[1]):")
        print(tabulate(conv_ch1_1, tablefmt='rounded_grid', floatfmt='.6f'))
        
        feature_map_0 = conv_ch1_0 + conv_ch1_1
        print("\nFeature Map 0 (Sum):")
        print(tabulate(feature_map_0, tablefmt='rounded_grid', floatfmt='.6f'))
        
        pooled_0 = max_pooling(feature_map_0)
        print("\nMax Pooling (3x3) -> 2x2:")
        print(tabulate(pooled_0, tablefmt='rounded_grid', floatfmt='.6f'))
        
        activated_0 = activation_func(pooled_0)
        print(f"\n{activation_name} Activation:")
        print(tabulate(activated_0, tablefmt='rounded_grid', floatfmt='.6f'))
        
        # Process Feature Map 1
        print("\n" + "="*80)
        print("Feature Map 1 = kernel_ch2[0] * img[0] + kernel_ch2[1] * img[1]")
        print("="*80)
        
        print("\nKernel_ch2[0]:")
        print(tabulate(pattern['kernel_ch2'][0], tablefmt='rounded_grid', floatfmt='.4f'))
        conv_ch2_0 = convolution(padded_0, pattern['kernel_ch2'][0])
        print("\nConv(kernel_ch2[0] * img[0]):")
        print(tabulate(conv_ch2_0, tablefmt='rounded_grid', floatfmt='.6f'))
        
        print("\nKernel_ch2[1]:")
        print(tabulate(pattern['kernel_ch2'][1], tablefmt='rounded_grid', floatfmt='.4f'))
        conv_ch2_1 = convolution(padded_1, pattern['kernel_ch2'][1])
        print("\nConv(kernel_ch2[1] * img[1]):")
        print(tabulate(conv_ch2_1, tablefmt='rounded_grid', floatfmt='.6f'))
        
        feature_map_1 = conv_ch2_0 + conv_ch2_1
        print("\nFeature Map 1 (Sum):")
        print(tabulate(feature_map_1, tablefmt='rounded_grid', floatfmt='.6f'))
        
        pooled_1 = max_pooling(feature_map_1)
        print("\nMax Pooling (3x3) -> 2x2:")
        print(tabulate(pooled_1, tablefmt='rounded_grid', floatfmt='.6f'))
        
        activated_1 = activation_func(pooled_1)
        print(f"\n{activation_name} Activation:")
        print(tabulate(activated_1, tablefmt='rounded_grid', floatfmt='.6f'))
        
        # Flatten feature vector
        feature_vec = np.concatenate([activated_0.flatten(), activated_1.flatten()])
        print("\n" + "="*80)
        print("Flattened Feature Vector (8 elements):")
        print("="*80)
        print(f"{feature_vec}")
        
        # Fully Connected Layer 1
        print("\n" + "="*80)
        print("Fully Connected Layer 1 (8 -> 5)")
        print("="*80)
        print(f"\nWeight1 shape: {pattern['weight1'].shape}")
        print(f"Bias1: {pattern['bias1']}")
        
        fc1_out = fully_connected(feature_vec, pattern['weight1'], pattern['bias1'])
        print(f"\nFC1 Output (before activation):")
        print(f"{fc1_out}")
        
        # Leaky ReLU
        fc1_activated = leaky_relu(fc1_out)
        print(f"\nLeaky ReLU (alpha=0.01):")
        print(f"{fc1_activated}")
        
        # Fully Connected Layer 2
        print("\n" + "="*80)
        print("Fully Connected Layer 2 (5 -> 3)")
        print("="*80)
        print(f"\nWeight2 shape: {pattern['weight2'].shape}")
        print(f"Bias2: {pattern['bias2']}")
        
        fc2_out = fully_connected(fc1_activated, pattern['weight2'], pattern['bias2'])
        print(f"\nFC2 Output (before softmax):")
        print(f"{fc2_out}")
        
        # Softmax
        output = softmax(fc2_out)
        print("\n" + "="*80)
        print("Softmax Output (Final Probabilities)")
        print("="*80)
        print(f"\n{output}")
        print(f"\nSum of probabilities: {np.sum(output):.6f}")
        print(f"Predicted class: {np.argmax(output)}")
            
    else:  # task == 1
        print("Original Image:")
        print(tabulate(pattern['image'], tablefmt='rounded_grid', floatfmt='.4f'))
        
        padded_img = padding_func(pattern['image'])
        print(f"\nPadded Image (8x8):")
        print(tabulate(padded_img, tablefmt='rounded_grid', floatfmt='.4f'))
        
        kernel_names = ['A', 'B', 'C', 'D']
        for idx, (kernel, name) in enumerate(zip(pattern['kernels'], kernel_names)):
            print(f"\n--- Kernel {name} ---")
            print(f"Kernel {name}:")
            print(tabulate(kernel, tablefmt='rounded_grid', floatfmt='.4f'))
            
            conv_result = convolution(padded_img, kernel)
            print(f"\nConvolution Result:")
            print(tabulate(conv_result, tablefmt='rounded_grid', floatfmt='.6f'))
            print(f"Sum of all elements: {np.sum(conv_result):.6f}")

if __name__ == "__main__":
    patterns = read_input_file('input.txt')
    
    for i, pattern in enumerate(patterns):
        if(i==9):
            print(f"\n\n{'#'*80}")
            print(f"# Pattern {i+1}")
            print(f"{'#'*80}")
            visualize_convolution(pattern)