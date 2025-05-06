Migrated EE JAR Comparator
====================

This sciprt determines whether a JAR is functionally changed by the [Apache EE Migration Tool](https://tomcat.apache.org/download-migration.cgi).

Specifically, on a list of local JARs, this runs the Apache Javax EE -> Jakarta EE migration tool, then compares 
the bytecodes of the original classes with the converted classes. 

# User Guide

## Prerequisites

### fd(find)

Instead of _find_, this script uses [fd](https://github.com/sharkdp/fd) to parrallelize the tasks.

### Apache Migration Tool for Jakarta EE 

This script assumes the [EE Migration Tool](https://tomcat.apache.org/download-migration.cgi) is on the host at 
_/user/local/bin/jakartaee-migration-1.0.9/bin/migrate.sh_.

### JDK 11

The value of the following must be 11 or greater.

```
$ javap -version;
```

## Execute

In the current directory must be:
* _current.txt_: A list of the paths of the JARs that are to be converted, one per line. Paths may be relative CWD.
* A directory containing the JARs 

The results are printed to STDOUT.  Diagnostic info is printed to STDERR. 

### Example of Excuting

```
$ ~/bin/eejarcompare/eejarcompare.sh  > /tmp/compare.stdout.log 2>/tmp/compare.stderr.log;
```

# Performance

On a 6 core i7 with 16G of memory, this is CPU bound, taking ~100 seconds per JAR.

