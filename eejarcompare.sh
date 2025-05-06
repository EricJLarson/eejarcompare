#!/bin/bash
set -e

#############
# Determine whether migrate.sh modified the JAR's bytecode.
# Prints results to STDOUT.
##############

# Prereq:"fd" -- For parallelization, use "fd" instead of "find". 
# Must be ran HIH/
# Migration tool location: ~/temp/jakartaee-migration-1.0.9/bin/migrate.sh 
# List of JARs: ./current.txt

export MIGRATIONTOOL=~/temp/jakartaee-migration-1.0.9/bin/migrate.sh;
[ -f ${MIGRATIONTOOL} ] || { echo ${MIGRATIONTOOL}' does not exist'; exit 2; } 
export JARLIST=current.txt;
[ -f ${JARLIST} ] || { echo ${JARLIST}' does not exist'; exit 2; } 

export JAKARTADIR=/tmp/nihjakarta;
export JAVAXDIR=/tmp/nihjavax;
rm -r ${JAKARTADIR} 2>/dev/null || true; # May not yet exist 
rm -r ${JAVAXDIR} 2>/dev/null || true;  # May not yet exist
mkdir ${JAKARTADIR};
mkdir ${JAVAXDIR};
export MIGRATIONTOOL=~/temp/jakartaee-migration-1.0.9/bin/migrate.sh;

# Arg: Takes a fully qualified JAR name 
# Prints the JAR name prepended by "CHANGED:" if the JAR was changed, otherwise "SAME:"
# Prereq:"fd" -- For parallelization, use "fd" instead of "find". 
# Must be ran HIH/
# Calls to this method are not threadsafe because directories JAVAXDIR and JAKARTADIR are shared
#    but this method itself is threaded by use of "fd".
compare() {
  echo "${JAR}:" >&2;
  START=$(date +%s);
  JARPATH=${1} &&\
  JAR=$(basename ${JARPATH}) &&\
  cp ${JARPATH} ${JAVAXDIR}/. &&\
  ${MIGRATIONTOOL} \
    -profile=EE \
    ${JAVAXDIR}/${JAR} \
    ${JAKARTADIR}/${JAR} &&\
  \
  pushd ${JAVAXDIR}/ > /dev/null &&\
  jar -xf ${JAR} &&\
  JAVAXMD5=$(fd -e class -x javap -c \; | sort | md5)  &&\
  popd > /dev/null &&\
  \
  pushd ${JAKARTADIR}/ > /dev/null &&\
  jar -xf ${JAR} &&\
  JAKARTAMD5=$(fd -e class -x javap -c \; | sort | md5)  &&\
  popd > /dev/null &&\
  \
  [ ${JAVAXMD5} == ${JAKARTAMD5} ] && echo "SAME:${JAR}:${JAVAXMD5:0:5}" || echo "CHANGED:${JAR}";
  rm -r ${JAKARTADIR}/${JAR};
  rm -r ${JAVAXDIR}/${JAR};
  END=$(date +%s);
  echo "DURATIONSECS:${JAR}:"$(( ${END} -  ${START} )) >&2;
}

export -f compare;
while read line; do
  compare ${line}; 
done < ${JARLIST};

