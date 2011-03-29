#!/bin/bash
UNCOMPENSATED_RESISTANCE=21.7
./tafel_cp.rb -f 'cp%d_1.txt' -u $UNCOMPENSATED_RESISTANCE -e 6 | tee tafel_1.csv
echo
./tafel_cp.rb -f 'cp%d_2.txt' -u $UNCOMPENSATED_RESISTANCE -e 5 | tee tafel_2.csv
echo
./tafel_cp.rb -f 'cp%d_3.txt' -u $UNCOMPENSATED_RESISTANCE -e 5 | tee tafel_3.csv
echo
./tafel_cp.rb -f 'cp%d_4.txt' -u $UNCOMPENSATED_RESISTANCE -e 5 | tee tafel_4.csv
echo
./tafel_cp.rb -f 'cp%d_5.txt' -u $UNCOMPENSATED_RESISTANCE -e 5 | tee tafel_5.csv
echo
./tafel_cp.rb -f 'cp%d_6.txt' -u $UNCOMPENSATED_RESISTANCE -e 3 | tee tafel_6.csv
