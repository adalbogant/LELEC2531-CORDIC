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
* Numbers in fixed-point format, with Q1.30 format (1 sign bit, 1 whole part bit and 30 decimal part bits), 2's complement
    * Ne jamais dépasser 1.9999... dans aucun cas (donc x + ... / y + ... / z + ...)
    => Essayer de rester < 0.66 pour les éléments des fractions

### Potentielles améliorations
* 3 LUTs pour z (une pour 2^-i en linéaire) VS calculer le deuxième input de z en mode linéaire on-the-fly
* Fusionner le résultat de la LUT pour linéaire, ciruclar et hyperbolic après i=10
* Enlever le arctanh(1) et gérer la première itération d'hyperbolic à part
* Restreindre l'angle entre -45° et 45° (et assurer l'angle entre -99.7° et 99.7°)
* On considère pour le moment que l'input x est déjà K en cas rotation circulaire ; ajouter un mécanisme de sélection des inputs corrects selon l'opération à effectuer
* Peut-être étendre le nombre de bit de la partie entière pour éviter les overflows durant les itérations

