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
        gdal_translate -of GTiff -outsize 174 51  $j/*B2.* $j/B2_100.TIF
        gdal_translate -of GTiff -outsize 174 51  $j/*B3.* $j/B3_100.TIF
        gdal_translate -of GTiff -outsize 174 51  $j/*B4.* $j/B4_100.TIF
        gdal_translate -of GTiff -outsize 174 51  $j/*B5.* $j/B5_100.TIF
        green=$j/B2_100.TIF
        blue=$j/B3_100.TIF
        ir=$j/B4_100.TIF
        swir=$j/B5_100.TIF
        x=51
        y=44
        z=99
    elif [[ $satellite = "2" ]]
    then
        gdal_translate -of GTiff -outsize 174 51  $j/*B3.* $j/B3_100.TIF
        gdal_translate -of GTiff -outsize 174 51  $j/*B4.* $j/B4_100.TIF
        gdal_translate -of GTiff -outsize 174 51  $j/*B5.* $j/B5_100.TIF
        gdal_translate -of GTiff -outsize 174 51  $j/*B6.* $j/B6_100.TIF
        green=$j/B3_100.TIF
        blue=$j/B4_100.TIF
        ir=$j/B5_100.TIF
        swir=$j/B6_100.TIF
        x=11468
        y=11468
        z=25558
    elif [[ $satellite = "3" ]]
    then
        gdal_translate -of GTiff -outsize 174 51  $j/*B03.* $j/B03_100.TIF
        gdal_translate -of GTiff -outsize 174 51  $j/*B04.* $j/B04_100.TIF
        gdal_translate -of GTiff -outsize 174 51  $j/*B08.* $j/B08_100.TIF
        gdal_translate -of GTiff -outsize 174 51  $j/*B11.* $j/B11_100.TIF
        green=$j/B03_100.TIF
        blue=$j/B04_100.TIF
        ir=$j/B08_100.TIF
        swir=$j/B11_100.TIF
        x=4400
        y=4400
        z=5100
    fi
    
    #Index calculation
    echo $r/$timestamp/indexes${j:p}
    #Clouds
    gdal_calc.py -A $green -B $blue -C $swir --outfile=$r/$timestamp/indexes${j:p}/CLOUDS.TIF --calc="100*logical_or (logical_and (C.astype(float)>$x,A.astype(float)>$y,((A.astype(float)-B.astype(float))/(A.astype(float)+B.astype(float)))>0),(A.astype(float)>$z))" --type="Float32" --NoDataValue=0
    #Snow
    gdal_calc.py -A $green -B $swir --outfile=$r/$timestamp/indexes${j:p}/NDSI.TIF --calc="((A.astype(float)-B.astype(float))/(A.astype(float)+B.astype(float)))*((A.astype(float)-B.astype(float))/(A.astype(float)+B.astype(float))>=0.42)" --type="Float32" --NoDataValue=0
    gdal_calc.py -A $r/$timestamp/indexes${j:p}/NDSI.TIF --outfile=$r/$timestamp/indexes${j:p}/SNOW.TIF --calc="((200+((A/0.58)-(0.42/0.58)))*(((A/0.58)-(0.42/0.58))>0))" --type="Float32" --NoDataValue=0
    #Vegetation
    gdal_calc.py -A $ir -B $blue --outfile=$r/$timestamp/indexes${j:p}/NDVI.TIF --calc="((A.astype(float)-B.astype(float))/(A.astype(float)+B.astype(float)))*((A.astype(float)-B.astype(float))/(A.astype(float)+B.astype(float))>0.2)" --type="Float32" --NoDataValue=0
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
