!#/bin/bash

TDIR=${HOME}




if [ "${TDIR}" == "" ]; then echo "HOME-DIR unknown"; exit 0; fi

EWSXTX="${TDIR}/ews.dsl/ews.xtx"

if [ ! -d ${EWSXTX} ] ; then
  echo "create eclipse working directory ${EWSXTX}";
  echo "install eclipse, xtext, xtend in accordance with the README.md";
  exit 0;
fi

OSCDDIR="${EWSXTX}/de.oscake.strict/src/de/oscake/strict/

if [ ! -d ${OSCDDIR} ] ; then
  echo "install eclipse, xtext, xtend in accordance with the README.md";
  exit 0;
fi

cp de.oscake.strict/src/de/oscake/strict/Oscd.xtext

# Entwicklungssicherung

# cp de.oscake.strict/src/de/oscake/strict/Oscd.xtext ~/gits/world/tdosca/OSCake/src/

cp de.oscake.strict/src/de/oscake/strict/generator/OscdGenerator.xtend ~/gits/world/tdosca/OSCake/src/

#cp de.oscake.weak/src/de/oscake/weak/Oscc.xtext ~/gits/world/tdosca/OSCake/src/

#cp de.oscake.weak/src/de/oscake/weak/generator/OsccGenerator.xtend ~/gits/world/tdosca/OSCake/src/
