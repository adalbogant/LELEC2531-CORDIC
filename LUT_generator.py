import numpy as np
import struct

# Generate values of angles (rad) in binary for the 3 LUTs (Circular, Linear, Hyperbolic)

N_FRAC, N_WHOLE, N_TOT = 30, 1, 32

def circular_angle(exp: int) -> str:
    
    angle = np.atan(2**(-exp))
    multiplied = angle * 2**30
    rounded = round(multiplied)
    binary = np.binary_repr(rounded, width=N_TOT)
    
    return binary


def hyperbolic_angle(exp: int) -> str:
    
    angle = np.arctanh(2**(-exp))
    multiplied = angle * 2**30
    rounded = round(multiplied)
    binary = np.binary_repr(rounded, width=N_TOT)
    
    return binary


def linear_angle(exp: int) -> str:
    
    angle = 2**(-exp)
    multiplied = angle * 2**30
    rounded = round(multiplied)
    binary = np.binary_repr(rounded, width=N_TOT)
    
    return binary


def decimal_part_checker(dec:str) -> float:
    res = 0
    for i, bit in enumerate(dec):
        res += float(bit) * 2**(-1-i)
    
    return res


# for i in range(32):
#     print(f"{i:>2} : {circular_angle(i)} {decimal_part_checker(circular_angle(i)[2:])}")
    
# for i in range(1, 33):
#     print(f"{i:>2} : {hyperbolic_angle(i)} {decimal_part_checker(hyperbolic_angle(i)[2:])}")
# for i in range(32):
#     print(f"{i:>2} : {linear_angle(i)} {decimal_part_checker(linear_angle(i)[2:])}")

print("CIRCULAR".center(25, "-"))
for i in range(32):
    print(circular_angle(i))
    
print("HYPERBOLIC".center(25, "-"))
for i in range(1, 33):
    print(hyperbolic_angle(i))
    
print("LINEAR".center(25, "-"))
for i in range(32):
    print(linear_angle(i))
