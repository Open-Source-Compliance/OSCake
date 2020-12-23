#!/bin/bash

TDIR=${HOME}

EWSXTX="${TDIR}/ews.dsl/ews.xtx"
EWSOSC="${TDIR}/ews.dsl/ews.osc"

if [ ! -d ${EWSXTX} ] ; then
  echo "create eclipse working directory ${EWSXTX}";
  echo "install eclipse, xtext, xtend in accordance with the README.md";
  exit 0;
fi

OSCD_SDIR="${EWSXTX}/de.oscake.strict/src/de/oscake/strict"
OSCD_TDIR=src
OSCD_FILE=Oscd.xtext
OSCD_GEN_FILE=OscdGenerator.xtend

OSCC_SDIR="${EWSXTX}/de.oscake.weak/src/de/oscake/weak"
OSCC_TDIR=src
OSCC_FILE=Oscc.xtext
OSCC_GEN_FILE=OsccGenerator.xtend

if [ ! -d ${OSCD_SDIR} ] ; then
  echo "install eclipse, xtext, xtend in accordance with the README.md";
  exit 0;
fi

if [ ! -d ${OSCC_SDIR} ] ; then
  echo "install eclipse, xtext, xtend in accordance with the README.md";
  exit 0;
fi

cp ${OSCC_SDIR}/${OSCC_FILE} ${OSCC_TDIR}/${OSCC_FILE}
cp ${OSCC_SDIR}/generator/${OSCC_GEN_FILE} ${OSCC_TDIR}/${OSCC_GEN_FILE}
cp ${OSCD_SDIR}/${OSCD_FILE} ${OSCD_TDIR}/${OSCD_FILE}
cp ${OSCD_SDIR}/generator/${OSCD_GEN_FILE} ${OSCD_TDIR}/${OSCD_GEN_FILE}
cp ${EWSOSC}/src/*.oscc test/a-input.oscc
cp ${EWSOSC}/src-gen/*.oscd test/b-output.oscc-eq-input.oscd
cp ${EWSOSC}/src-gen/*.md test/c-output.oscf.md
