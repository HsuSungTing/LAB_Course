# ICLAB Lab1 Test Case Generator

This tool generates test patterns for the **MPCA** lab assignment.  
It produces two files:  

- **input.txt** (hexadecimal format):  
    ```
    [packet0]
    [packet1]
    ...
    [packet7]
    [KEY] (64-bit)
    [channel_load0]
    [channel_load1]
    [channel_load2]
    [channel_capacity0]
    [channel_capacity1]
    [channel_capacity2]
    ```
- **output.txt** (decimal 0–3):
    ```
    [grant_channel0]
    [grant_channel1]
    ...
    [grant_channel7]
    ```


---

## How to Use

### Generate random patterns
```bash
python3 gen_patterns.py -n 1000 --seed 42 -i input.txt -o output.txt
```
This generates 1000 patterns with a fixed random seed for reproducibility.

### Run the built-in document test cases
Example 1:
```
python3 gen_patterns.py --test1
```
Example 2:
```
python3 gen_patterns.py --test2
```

## Contact
Welcome to communicate or report issues via: `blitz23555@gmail.com`

