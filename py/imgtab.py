# -*- coding: utf-8 -*-

#!/usr/bin/env python3

import sys, os.path
from collections import Counter
from osgeo import gdal_array

if __name__ == '__main__':
    args = sys.argv[ 1: ]
    inPath_V = os.path.normpath( args[ 0 ] )
    inPath_M = os.path.normpath( args[ 1 ] )
    outPath = os.path.normpath( args[ 2 ] )
    nameString = os.path.normpath( args[ 3 ] )

infile_V = str(open(inPath_V)).replace("<_io.TextIOWrapper name='", "")
infile_V = infile_V.replace("' mode='r' encoding='UTF-8'>", "")
infile_M = str(open(inPath_M)).replace("<_io.TextIOWrapper name='", "")
infile_M = infile_M.replace("' mode='r' encoding='UTF-8'>", "")

#Read raster data as numeric array from file
rasterArray_V = gdal_array.LoadFile(infile_V)
rasterArray_M = gdal_array.LoadFile(infile_M)

#Formatting data
table_V = [str(Counter(rasterArray_V.flatten()))]
table_V = [i.replace("Counter({", "") for i in table_V]
table_V = [i.replace("})", "") for i in table_V]
table_V = [i.replace(" ", "") for i in table_V]
table_M = [str(Counter(rasterArray_M.flatten()))]
table_M = [i.replace("Counter({", "") for i in table_M]
table_M = [i.replace("})", "") for i in table_M]
table_M = [i.replace(" ", "") for i in table_M]

datastring_V = ','.join(table_V)
datastring_M = ','.join(table_M)

datastring_V = (datastring_V.strip().split(','))
datastring_M = (datastring_M.strip().split(','))

all_px = 0
clouds_px = 0
snow_px = 0
veg_px = 0
i_s = 0
i_v = 0
i_m = 0
snow_i = 0
veg_i = 0
mois_i = 0

for i in range(len(datastring_V)):
    a = datastring_V[i].find(':')
    #Counting the sum of pixels, all except "nan"
    if datastring_V[i][0:a] == 'nan':
        all_px = all_px
    elif datastring_V[i][0:a] == '0.0':
        all_px = all_px + float(datastring_V[i][a+1:])
    elif datastring_V[i][0:a] == '100.0':
        all_px = all_px + float(datastring_V[i][a+1:])
        clouds_px = clouds_px + float(datastring_V[i][a+1:])
    elif float(datastring_V[i][0:a]) > 200 and float(datastring_V[i][0:a]) < 300:
        all_px = all_px + float(datastring_V[i][a+1:])
        snow_px = snow_px + float(datastring_V[i][a+1:])
        i_s = i_s + 1
        snow_i = snow_i + float(datastring_V[i][0:a]) - 200
    elif float(datastring_V[i][0:a]) > 300:
        all_px = all_px + float(datastring_V[i][a+1:])
        veg_px = veg_px + float(datastring_V[i][a+1:])
        i_v = i_v + 1
        veg_i = veg_i + float(datastring_V[i][0:a]) - 300
        
for i in range(len(datastring_M)):
    a = datastring_M[i].find(':')
    if float(datastring_M[i][0:a]) > 400:
        i_m = i_m + 1
        mois_i = mois_i + float(datastring_M[i][0:a]) - 400
        
if i_s > 0:
    snow_i = (snow_i / i_s)
else:
    snow_i = 0 
if i_v > 0:
    veg_i = (veg_i / i_v)
else:
    veg_i = 0
if i_m > 0:
    mois_i= (mois_i / i_m)
else:
    mois_i= 0
clouds = (clouds_px / all_px) * 100
if all_px > clouds_px:
    snow = (snow_px / (all_px-clouds_px)) * 100
    veg = (veg_px / (all_px-clouds_px)) * 100
else:
    snow = 0
    veg = 0
       
#Writing data to a file
outfile = open(outPath, 'a')
data = [nameString,str(clouds),str(snow),str(snow_i),str(veg), str(veg_i), str(mois_i)]
print(','.join(data), file = outfile)
outfile.close
