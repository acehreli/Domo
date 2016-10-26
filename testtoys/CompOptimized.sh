#!/bin/bash
#
# $Id$
#
ProgName="BigEndianExtraction"
#
gdc ${ProgName}.d -o ${ProgName}
echo "No Optimization at all."
./${ProgName}
#
gdc -O1 ${ProgName}.d -o ${ProgName}
echo "-O1 Optimization"
./${ProgName}
#
gdc -O1 -fno-bounds-check -finline-functions ${ProgName}.d -o ${ProgName}
echo "-O1 Optimization +(no bounds check, inline)"
./${ProgName}
#
gdc -Os -fno-bounds-check -finline-functions ${ProgName}.d -o ${ProgName}
echo "-Os Optimization +(no bounds check, inline)"
./${ProgName}
#
gdc -O2 ${ProgName}.d -o ${ProgName}
echo "-O2 Optimization"
./${ProgName}
#
gdc -O2 -fno-bounds-check -finline-functions ${ProgName}.d -o ${ProgName}
echo "-O2 Optimization +(no bounds check, inline)"
./${ProgName}
#
gdc -O3 -fno-bounds-check -finline-functions ${ProgName}.d -o ${ProgName}
echo "-O3 Optimization +(no bounds check, inline)"
./${ProgName}

# Strip ${ProgName}
echo "Results of strip(1):"
echo -n "Before: "
ls -lh ${ProgName}
strip ${ProgName}
echo -n "After:  "
ls -lh ${ProgName}
