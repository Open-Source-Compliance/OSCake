#!/bin/bash

REPODIR=${HOME}

EWSXTX="${REPODIR}/ews.dsl/ews.xtx"

if [ ! -d ${EWSXTX} ] ; then
  echo "create eclipse working directory ${EWSXTX}";
  echo "install eclipse, xtext, xtend in accordance with the README.md";
  exit 0;
fi

OSCF_DEVDIR="${EWSXTX}/de.oscake.strict/src/de/oscake/strict"
OSCF_REPODIR=src
OSCF_FILE=Oscf.xtext
OSCF_GEN_FILE=OscfGenerator.xtend

OSCC_DEVDIR="${EWSXTX}/de.oscake.weak/src/de/oscake/weak"
OSCC_REPODIR=src
OSCC_FILE=Oscc.xtext
OSCC_GEN_FILE=OsccGenerator.xtend

if [ ! -d ${OSCF_DEVDIR} ] ; then
  echo "install eclipse, xtext, xtend in accordance with the README.md";
  exit 0;
fi

if [ ! -d ${OSCC_DEVDIR} ] ; then
  echo "install eclipse, xtext, xtend in accordance with the README.md";
  exit 0;
fi

cp ${OSCC_DEVDIR}/${OSCC_FILE} ${OSCC_REPODIR}/${OSCC_FILE}
cp ${OSCC_DEVDIR}/generator/${OSCC_GEN_FILE} ${OSCC_REPODIR}/${OSCC_GEN_FILE}
cp ${OSCF_DEVDIR}/${OSCF_FILE} ${OSCF_REPODIR}/${OSCF_FILE}
cp ${OSCF_DEVDIR}/generator/${OSCF_GEN_FILE} ${OSCF_REPODIR}/${OSCF_GEN_FILE}
