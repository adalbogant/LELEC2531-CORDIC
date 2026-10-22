# FPGA CORDIC Implementation in SystemVerilog.

### Conventions

| **Variable**    | **Value** | **Meaning** |
| :-------- | :-------: | :------- |
| Mode  | 0 | Rotation |
| Mode | 1 | Vectoring |
| Coordinates system | 00 | Linear mode |
| Coordinates system | 01 | Circular mode |
| Coordinates system | 11 | Hyperbolic mode |
| Coordinates system | 10 | Defaults on linear mode |

* Angles in radians
* Numbers in fixed-point format, with Q1.30 format (1 sign bit, 1 whole part bit and 30 decimal part bits)

### Potentielles améliorations
* 3 LUTs pour z (une pour 2^-i en linéaire) VS calculer le deuxième input de z en mode linéaire on-the-fly
* Restreindre l'angle entre -45° et 45° (et assurer l'angle entre -99.7° et 99.7°)

