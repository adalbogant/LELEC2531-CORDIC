import numpy as np
from math import pi
import sys
sys.stdout.reconfigure(encoding="utf-8") # To get the ° symbol when printing in console
# Because it will probably be faster and less boring to generate the tb like this

def to_rad(angle: float) ->  float:
    return round(angle * pi / 180, ndigits=10)


def gen_test_str(xi, yi, zi, mode, coord, xo, yo, zo, testval, tol):
    test_str = f"test({xi}, {yi}, {zi}, {mode}, {coord}, {xo}, {yo}, {zo}, {testval}, {tol});"
    return test_str


def get_circular_rotation(angle: float) -> str:
    xi = "K_CIRC"
    yi = 0
    zi = to_rad(angle)
    mode = "1'b0"
    coord = "2'b01"
    xo = np.cos(zi)
    yo = np.sin(zi)
    zo = 0
    testval = "3'b111"
    tol = "TOL"
    commentary = f"\t// z_in = {angle}\u00B0 = {zi} rad\n\t// cos(z_in) = {round(xo, 10)}\n\t// sin(z_in) = {round(yo, 10)}"
    
    return commentary + "\n\t" + gen_test_str(xi, yi, zi, mode, coord, round(xo, 10), round(yo, 10), zo, testval, tol)


def get_circular_vectoring(argument: float) -> str:
    # Want to avoid overflow when xi and yi are too big (1 whole bit => max =~ 2)
    # Reducing the fraction yi / xi to (yi / 2*arg) / (xi / 2arg) will guarantee (I think so) that these values won't go above 2.
    # Taking yi_old = arg and xi_old = 1, we end up with yi_new = 0.5 and xi_new = 1 / 2arg
    # frac = 0.5 / (0.5 / arg) = 0.5 * arg / 0.5 = arg; but with small values to avoid overflow
    # However, if the argument is already much smaller than 1, we can't take its inverse, instantly causing overflow
    # In that case, just take arg = 0.5*arg / 0.5
    xi = 0.5 / argument if abs(argument) > 1 else 0.5
    yi = 0.5 if abs(argument) > 1 else 0.5 * argument
    zi = 0
    mode = "1'b1"
    coord = "2'b01"
    xo = 0 # Not actually, but we only care about the z value (arctan)
    yo = 0
    zo = np.atan(yi/xi)
    testval = "3'b001"
    tol = "TOL"
    commentary = f"\t// arg = {round(argument, 10)} = {yi} / {round(xi, 10)}\n\t// arctan(arg) = {round(zo, 10)} (rad)"
    
    return commentary + "\n\t" + gen_test_str(round(xi, 10), yi, zi, mode, coord, xo, yo, round(zo, 10), testval, tol)


def get_linear_rotation(factor1: float, factor2: float) -> str:
    # If the result of the multiplication of the two factors would already bring the result above 2, 
    # there is really no way of avoiding overflow, so...
    xi = factor1
    yi = 0
    zi = factor2
    mode = "1'b0"
    coord = np.random.choice(["2'b00", "2'b10"]) # 2'b00 is normal Linear case, but 2'b10 defaults to Linear as well (X sign MUX)
    xo = xi # X doesn't move but we don't really care, just want the product y
    yo = xi * zi
    zo = 0
    testval = "3'b010"
    tol = "TOL"
    commentary = f"\t// {round(factor1, 10)} * {round(factor2, 10)} = {round(yo, 10)}"
    
    return commentary + "\n\t" + gen_test_str(round(xi, 10), yi, round(zi, 10), mode, coord, round(xo, 10), round(yo, 10), zo, testval, tol)


def get_linear_vectoring(numerator: float, denominator: float) -> str:
    # Once again, can't really do anything to prevent the result from overflowing there, if y/x gives something above 2, it will be wrong
    xi = denominator
    yi = numerator
    zi = 0
    mode = "1'b1"
    coord = np.random.choice(["2'b00", "2'b10"]) # 2'b00 is normal Linear case, but 2'b10 defaults to Linear as well (X sign MUX)
    xo = xi # X doesn't move but we don't really care, just want the quotient z
    yo = 0
    zo = yi / xi
    testval = "3'b001"
    tol = "TOL"
    commentary = f"\t// {round(numerator, 10)} / {round(denominator, 10)} = {round(zo, 10)}"
    
    return commentary + "\n\t" + gen_test_str(round(xi, 10), round(yi, 10), zi, mode, coord, round(xo, 10), yo, round(zo, 10), testval, tol)


def get_hyperbolic_rotation(angle: float) -> str:
    xi = "K_HYPERBOLIC"
    yi = 0
    zi = to_rad(angle)
    mode = "1'b0"
    coord = "2'b11"
    xo = round(np.cosh(zi), 10)
    yo = round(np.sinh(zi), 10)
    zo = 0
    testval = "3'b111"
    tol = "TOL_HYPERBOLIC"
    commentary = f"\t// z_in = {angle}\u00B0 = {zi} rad\n\t// cosh(z_in) = {xo}\n\t// sinh(z_in) = {yo}"
    
    return commentary + "\n\t" + gen_test_str(xi, yi, zi, mode, coord, xo, yo, zo, testval, tol)


def get_hyperbolic_vectoring(argument: float) -> str:
    # Same input management as for circular vectoring, don't need to compute the result of the input fraction, just the arctanh
    # But arctanh can also go above 2, which is impossible to prevent.
    xi = 0.5 / argument if abs(argument) > 1 else 0.5
    yi = 0.5 if abs(argument) > 1 else 0.5 * argument
    zi = 0
    mode = "1'b1"
    coord = "2'b11"
    xo = 0 # Not actually, but we only care about the z value (arctanh)
    yo = 0
    zo = np.atanh(yi/xi)
    testval = "3'b001"
    tol = "TOL_HYPERBOLIC"
    commentary = f"\t// arg = {round(argument, 10)} = {yi} / {round(xi, 10)}\n\t// arctanh({round(argument, 10)}) = {round(zo, 10)} (rad)"
    
    return commentary + "\n\t" + gen_test_str(round(xi, 10), yi, zi, mode, coord, xo, yo, round(zo, 10), testval, tol)

# TO TEST ONE FOR EACH CASE
# print(get_circular_rotation(33))
# print()
# print(get_circular_vectoring(np.sqrt(3)))
# print()
# print(get_linear_rotation(0.6, 0.7))
# print()
# print(get_linear_vectoring(0.42, 0.7))
# print()
# print(get_hyperbolic_rotation(40))
# print()
# print(get_hyperbolic_vectoring(0.67))

CR_angles = [0, 5, -21, 33, 45, -67, -90]
CV_args = [0, -0.5, 1, np.sqrt(3), -2.5, 3, -6.7]
LR_factors = [(0.6, 0.7), (0, 0.8), (0.5, 0.5), (-0.8, 0.8), (-0.5, -0.5)]
LV_fracs = [(0.42, 0.7), (0.06, -0.7), (0.19, 0.1), (-0.1, -0.1), (0, 1)] # Could be interesting to test a division by 0 here
HR_angles = [0, 11, -27, 40, 67, 90]
HV_args = [0, 0.13, -0.42, 0.67, -0.9] # Could be interesting to test arctanh(>=1) here

print("\t// -----------------------------\n\t// ----- CIRCULAR ROTATION -----\n\t// -----------------------------")
for angle in CR_angles:
    print(get_circular_rotation(angle))
    print()
    
print("\t// ------------------------------\n\t// ----- CIRCULAR VECTORING -----\n\t// ------------------------------")
for arg in CV_args:
    print(get_circular_vectoring(arg))
    print()
    
print("\t// ---------------------------\n\t// ----- LINEAR ROTATION -----\n\t// ---------------------------")
for factor1, factor2 in LR_factors:
    print(get_linear_rotation(factor1, factor2))
    print()

print("\t// ----------------------------\n\t// ----- LINEAR VECTORING -----\n\t// ----------------------------")
for num, denom in LV_fracs:
    print(get_linear_vectoring(num, denom))
    print()
    
print("\t// -------------------------------\n\t// ----- HYPERBOLIC ROTATION -----\n\t// -------------------------------")
for angle in HR_angles:
    print(get_hyperbolic_rotation(angle))
    print()
    
print("\t// --------------------------------\n\t// ----- HYPERBOLIC VECTORING -----\n\t// --------------------------------")
for arg in HV_args:
    print(get_hyperbolic_vectoring(arg))
    print()