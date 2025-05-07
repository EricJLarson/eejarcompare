#!/bin/bash
set -e

#############
# Determine whether migrate.sh modified the JAR's bytecode.
# Prints results to STDOUT.
##############
# Prereqs:
#   * "fd" -- For parallelization, use "fd" instead of "find". 
#   * Must be ran directory containing the JARs, e.g. NIH/ 
#   * Migration tool location: /usr/local/bin/jakartaee-migration-1.0.9/bin/migrate.sh;
#   * List of JARs: ./current.txt

export MIGRATIONTOOL=/usr/local/bin/jakartaee-migration-1.0.9/bin/migrate.sh;
[ -f ${MIGRATIONTOOL} ] || { echo ${MIGRATIONTOOL}' does not exist'; exit 2; } 
[ $# -ne 1 ] && { echo 'Use:'${0}' JARLISTFILE'; exit 2; }
export JARLIST="${1}";
[ -f ${JARLIST} ] || { echo ${JARLIST}' does not exist'; exit 2; } 
JDKVERS=$(javap -version 2>&1 | awk -F '.' '{print $1}' )
[ ${JDKVERS} -ge 11 ] || { echo "JDK 11 or later required"; exit 2; }


export JAKARTAROOTDIR=/tmp/nihjakarta;
export JAVAXROOTDIR=/tmp/nihjavax;
rm -r ${JAKARTAROOTDIR} 2>/dev/null || true; # May not yet exist 
rm -r ${JAVAXROOTDIR} 2>/dev/null || true;  # May not yet exist
mkdir ${JAKARTAROOTDIR};
mkdir ${JAVAXROOTDIR};

# Arg: Takes a JAR file name and path relative to CWD.
# Prints the JAR name prepended by "CHANGED:" if the JAR was changed, otherwise "SAME:"
# This method itself creates concurrency by using "fd".
compare() {
  echo "${JAR}:" >&2;
  START=$(date +%s);
  JARPATH=${1}; 
  JAR=$(basename ${JARPATH}); 
  JARPREFIX="${JAR%.*}"; # JAR filename sans ".jar"
  JAVAXDIR=${JAVAXROOTDIR}/${JARPREFIX};
  mkdir ${JAVAXDIR};
  JAKARTADIR=${JAKARTAROOTDIR}/${JARPREFIX};
  mkdir ${JAKARTADIR};
  cp ${JARPATH} ${JAVAXDIR}/.; 
  ${MIGRATIONTOOL} \
    -profile=EE \
    ${JAVAXDIR}/${JAR} \
    ${JAKARTADIR}/${JAR}; 
  
  pushd ${JAVAXDIR}/ > /dev/null; 
  jar -xf ${JAR};
  # Using "sort" to put the results of the two "fd" calls in a form common to both.
  # Because "fd" runs parallel jobs, the results arrive randomly. "fd | sort" is a map-reduce.   
  JAVAXMD5=$(fd -e class -x javap -c \; | sort | md5);
  popd > /dev/null;
  
  pushd ${JAKARTADIR}/ > /dev/null;
  jar -xf ${JAR};
  JAKARTAMD5=$(fd -e class -x javap -c \; | sort | md5);
  popd > /dev/null; 
  
  [ ${JAVAXMD5} == ${JAKARTAMD5} ] && echo "SAME:${JAR}:${JAVAXMD5:0:5}" || echo "CHANGED:${JAR}";
  rm -r ${JAKARTADIR};
  rm -r ${JAVAXDIR};
  END=$(date +%s);
  echo "DURATIONSECS:${JAR}:"$(( ${END} -  ${START} )) >&2;
}

export -f compare;
while read line; do
  compare ${line}; 
done < ${JARLIST};

