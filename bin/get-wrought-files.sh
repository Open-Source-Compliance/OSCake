#!/bin/bash

TDIR=${HOME}

EWSXTX="${TDIR}/ews.dsl/ews.xtx"
EWSOSC="${TDIR}/ews.dsl/ews.osc"

if [ ! -d ${EWSXTX} ] ; then
  echo "create eclipse working directory ${EWSXTX}";
  echo "install eclipse, xtext, xtend in accordance with the README.md";
  exit 0;
fi

OSCF_SDIR="${EWSXTX}/de.oscake.strict/src/de/oscake/strict"
OSCF_TDIR=src
OSCF_FILE=Oscf.xtext
OSCF_GEN_FILE=OscfGenerator.xtend

OSCC_SDIR="${EWSXTX}/de.oscake.weak/src/de/oscake/weak"
OSCC_TDIR=src
OSCC_FILE=Oscc.xtext
OSCC_GEN_FILE=OsccGenerator.xtend

if [ ! -d ${OSCF_SDIR} ] ; then
  echo "install eclipse, xtext, xtend in accordance with the README.md";
  exit 0;
fi

if [ ! -d ${OSCC_SDIR} ] ; then
  echo "install eclipse, xtext, xtend in accordance with the README.md";
  exit 0;
fi

cp ${OSCC_SDIR}/${OSCC_FILE} ${OSCC_TDIR}/${OSCC_FILE}
cp ${OSCC_SDIR}/generator/${OSCC_GEN_FILE} ${OSCC_TDIR}/${OSCC_GEN_FILE}
cp ${OSCF_SDIR}/${OSCF_FILE} ${OSCF_TDIR}/${OSCF_FILE}
cp ${OSCF_SDIR}/generator/${OSCF_GEN_FILE} ${OSCF_TDIR}/${OSCF_GEN_FILE}
cp ${EWSOSC}/src/*.oscc test/a-input.oscc
cp ${EWSOSC}/src-gen/*.oscf test/b-output.oscc-eq-input.oscf
cp ${EWSOSC}/src-gen/*.md test/c-output.oscf.md
