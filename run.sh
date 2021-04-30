#/bin/bash

#Date and time of the start of the program 
timestamp=$(date +"%Y""%m""%d""%H""%M""%S")
starttime=$(date +"%Y""/""%m""/""%d"" ""%H"":""%M"":""%S")
echo "START:" $starttime

#Data input
read -p "The path to the folder with images: " path
p=${#path}
read -p "Satellite selection
Landsat 4, 5, 7 <1> 
Landsat 8 <2> 
Sentinel 2 <3> 
Enter the number: " satellite
read -p "Cut file path: " area

#Create a time stamp folder
r=$(realpath ./out)
mkdir $r/$timestamp
mkdir $r/$timestamp/tab

#Path to folder "py"
py=$(realpath ./py)

#Creating an output file "out.csv"
python3 $py/addtab.py $r/$timestamp/tab/out.csv

#Cropping images
#Loop through all subfolders of a given path 
for j in $(find $path -type d)
do
    
    #Defining File Saving Paths
    y=${#j}
    mkdir $r/$timestamp/crop${j:p}
    mkdir $r/$timestamp/indexes${j:p}
    
    #File selection
    for i in $(find "$j" -maxdepth 1 -type f -iname "*.TIF" | sort -g)
    do
    
    #Crop images and save to "out" folder
    gdalwarp -cutline $area -crop_to_cutline $i $r/$timestamp/crop${j:p}${i:y}
    done
done

#Obtaining masks 
#Loop through all subfolders "~/crop"
path=$r/$timestamp/crop
p=${#path}
for j in $(find $r/$timestamp/crop -type d)
do      
    #Assigning values depending on the satellite 
    if [[ $satellite = "1" ]]
    then
        green=$j/*B2.*
        red=$j/*B3.*
        ir=$j/*B4.*
        swir=$j/*B5.*
        x=51
        y=44
        z=99
    elif [[ $satellite = "2" ]]
    then
        green=$j/*B3.*
        red=$j/*B4.*
        ir=$j/*B5.*
        swir=$j/*B6.*
        x=11468
        y=11468
        z=25558
    elif [[ $satellite = "3" ]]
    then
        green=$j/*B03.*
        red=$j/*B04.*
        ir=$j/*B08.*
        swir=$j/*B11.*
        x=4400
        y=4400
        z=5100
    fi
    
    #Index calculation
    echo $r/$timestamp/indexes${j:p}
    #Clouds
    gdal_calc.py -A $green -B $red -C $swir --outfile=$r/$timestamp/indexes${j:p}/CLOUDS.TIF --calc="100*logical_or (logical_and (C.astype(float)>$x,A.astype(float)>$y,((A.astype(float)-B.astype(float))/(A.astype(float)+B.astype(float)))>0),(A.astype(float)>$z))" --type="Float32" --NoDataValue=0
    #Snow
    gdal_calc.py -A $green -B $swir --outfile=$r/$timestamp/indexes${j:p}/NDSI.TIF --calc="((A.astype(float)-B.astype(float))/(A.astype(float)+B.astype(float)))*((A.astype(float)-B.astype(float))/(A.astype(float)+B.astype(float))>=0.42)" --type="Float32" --NoDataValue=0
    gdal_calc.py -A $r/$timestamp/indexes${j:p}/NDSI.TIF --outfile=$r/$timestamp/indexes${j:p}/SNOW.TIF --calc="((200+((A/0.58)-(0.42/0.58)))*(((A/0.58)-(0.42/0.58))>0))" --type="Float32" --NoDataValue=0
    #Vegetation
    gdal_calc.py -A $ir -B $red --outfile=$r/$timestamp/indexes${j:p}/NDVI.TIF --calc="((A.astype(float)-B.astype(float))/(A.astype(float)+B.astype(float)))*((A.astype(float)-B.astype(float))/(A.astype(float)+B.astype(float))>0.2)" --type="Float32" --NoDataValue=0
    gdal_calc.py -A $r/$timestamp/indexes${j:p}/NDVI.TIF --outfile=$r/$timestamp/indexes${j:p}/VEG.TIF --calc="((300+((A/0.8)-(0.2/0.8)))*(((A/0.8)-(0.2/0.8))>0))" --type="Float32" --NoDataValue=0
    #Moisture
    gdal_calc.py -A $ir -B $swir --outfile=$r/$timestamp/indexes${j:p}/NDMI.TIF --calc="(((A.astype(float)-B.astype(float))/(A.astype(float)+B.astype(float))))*((A.astype(float)-B.astype(float))/(A.astype(float)+B.astype(float))>-0.2)" --type="Float32" --NoDataValue=0
    gdal_calc.py -A $r/$timestamp/indexes${j:p}/NDMI.TIF --outfile=$r/$timestamp/indexes${j:p}/MOIS.TIF --calc="((400+((A/1.2)+(0.2/1.2)))*(((A/1.2)+(0.2/1.2))>0))" --type="Float32" --NoDataValue=0
    
done

#Loop through all subfolders "~/indexes"
path=$r/$timestamp/indexes
p=${#path}
for j in $(find $r/$timestamp/indexes -type d)
do
   
    #Combining rasters
    gdal_merge.py -o $j/MERGE_V.TIF $j/VEG.TIF $j/CLOUDS.TIF $j/SNOW.TIF
    gdal_merge.py -o $j/MERGE_M.TIF $j/MOIS.TIF $j/CLOUDS.TIF $j/SNOW.TIF
done

#Loop through all subfolders "~/indexes"
path=$r/$timestamp/indexes
p=${#path}
for j in $(find $r/$timestamp/indexes -type d)
do
    #Adding data to a table
    python3 $py/imgtab.py  $j/MERGE_V.TIF $j/MERGE_M.TIF $r/$timestamp/tab/out.csv ${j:p}
done
echo "START:" $starttime
echo "END:" $(date +"%Y""/""%m""/""%d"" ""%H"":""%M"":""%S")
