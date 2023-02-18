#!/bin/bash

#present working directory
pwd=$(pwd)

#use input file to import the variables
source ./elastic_search_input_file.txt

#declare an array to store all the indices present
declare -a array

#use below command to store all indices in an array
array+=($(curl -XGET "http://$host:9200/_cat/indices" | awk '{print $3}' | grep -v "^\."))


#for element in "${array[@]}"
#do
#    echo $element
#done

for i in "${array[@]}"
do
        echo $i >> $pwd/temp.txt
done

