#!/bin/bash

##
##  Example anonymization script for Mac which uses Docker for native ImageIO
##  Place DICOM with PHI in the 'DICOM' directory
##  and it will write anonymized DICOM to 'DICOM-ANON'
## 

##  Input file should be supplied as a command line
##  argument to this script, in the form:
##  pat_0dfeb6f170_acc_edcd28452afb

# The new, anonymous patient ID
# (extracted from the input filename)
PATIENTID=$(echo $1 | awk -F'_' '{ print $2 }')
# The new, anonymous, accession number:
ACCESSION=$(echo $1 | awk -F'_' '{ print $4 }')

INPUT_DN=DICOM
OUTPUT_DN=DICOM-ANON

mkdir -p $"${INPUT_DN}"
mkdir -p $"${OUTPUT_DN}"

# Anonymize dates by subtracting or adding this value, in days:
JITTER="-10"

OPTIND=1

while getopts "h?vd" opt; do
    case "$opt" in
    h|\?)
        echo "Usage: $0 -dv"
        echo "  -d  Wait for Java debugger to attach to port 8000"
        echo "  -v  Verbose output"
        exit 0
        ;;
    v)  VERBOSE="-Dlog4j.configuration=file:/app/log4j.properties"
        ;;
    d)  DEBUG="-agentlib:jdwp=transport=dt_socket,address=8000,server=y,suspend=y"
        echo "Java debugging enabled"
        ;;
    esac
done

shift $((OPTIND-1))
[[ "${1:-}" = "--" ]] && shift

docker run --rm  -e JAVA_TOOL_OPTIONS=${DEBUG} \
    -p 8000:8000 -v ${PWD}/scripts:/scripts -v ${PWD}:/data/dicom mirc-ctp java ${VERBOSE} -cp /app/DAT/* org.rsna.dicomanonymizertool.DicomAnonymizerTool -v -n 8 \
	-in "/data/dicom/${INPUT_DN}" \
	-out "/data/dicom/${OUTPUT_DN}" \
	-dec \
	-rec \
	-f /scripts/stanford-filter.script \
	-da /scripts/stanford-anonymizer.script \
	-dpa /scripts/stanford-scrubber.script \
	-pPATIENTID "$PATIENTID" \
	-pJITTER "$JITTER" \
	-pACCESSION "$ACCESSION"
