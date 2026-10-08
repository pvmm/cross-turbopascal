#   Compilation TCL Script Copyright (C) since whatever by Ricardo Jurczyk Pinheiro
#   Based on HardDisk loader from PopolonY2K
#   This program comes with ABSOLUTELY NO WARRANTY;
#   This is free software, and you are welcome to redistribute it
#   under certain conditions;
#
#   variables to replace: DRIVE, SANDBOX (use it like this: %%<VARNAME>%%)
#
#   DRIVE             the hard disk file that will be used
#   SANDBOX           the directory where files are temporarily stored

# Aqui ele define qual será a imagem de HD a ser usada. Usamos uma que tem
# várias ferramentas de desenvolvimento.

set hdfile "%%DRIVE%%" ; # o arquivo com a imagem de HD que será usado

# Aqui ele desliga o MSX, define que vai usar uma interface IDE e seta qual
# é o HD.

set power off
ext ram4mb
ext ide
hda $hdfile

# Aqui, ele formata a 4a partição, e importa do sandbox para ser essa partição.

diskmanipulator format hda4
diskmanipulator import hda4 "%%SANDBOX%%"

# Aqui, ele liga o MSX e faz um overclock de 10000% (MSX on firah). 

set power on
after boot "set speed 10000"

# Após 15 unidades de tempo, ele executa o script COMPILA.BAT.
after time 20 "type \"d:step1.bat\\r\""
