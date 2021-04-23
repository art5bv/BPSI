# -*- coding: utf-8 -*-

#!/usr/bin/env python3
#Creating a table
import sys, os.path
 
if __name__ == '__main__':
    args = sys.argv[ 1: ]
    outPath = os.path.normpath( args[ 0 ] )

outfile = open(outPath, 'w')
data = ["NAME","CLOUDS_%","SNOW_%","SNOW_index","VEGETATION_%","VEGETATION_index","MOISTURE_index"]
print(','.join(data), file = outfile)
outfile.close
