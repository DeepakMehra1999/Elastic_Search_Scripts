
#! /bin/bash

#import all the variables required from an input file
source ./elastic_search_input_file.txt

#present working directory
pwd=$(pwd)

#make a directory and store recent backup in this folder
mkdir -p $dir/$final_es_backup_folder

cd $dir
sudo chmod 777 $final_es_backup_folder
#move to the folder where backup tar file present
cd $path_of_directory_where_all_backup_tar_files_present

#store the recent backup tar file path in a separate variable
latest_tar=$(ls -t $path_of_directory_where_all_backup_tar_files_present/*.tar | head -1)

#store it's file name in another variable
file_name=$(basename "$latest_tar")

#move recent backup to final_es_backup_folder
cp $latest_tar $dir/$final_es_backup_folder

#move to the final_es_backup_folder
cd $dir/$final_es_backup_folder

#untar this file
tar -xf $file_name

#store the directory name after untar it in a variable
dir_name=$(tar -tf $file_name | head -1 | cut -f1 -d"/")


#add these lines in elasticsearch.yml before taking backup
#echo "node.name: 'node-1'" >> $path_of_elastic_search_directory/elasticsearch.yml
#echo "cluster.initial_master_nodes: ['node-1']" >> $path_of_elastic_search_directory/elasticsearch.yml
echo "path.repo: ['$dir/$final_es_backup_folder/$dir_name']" >> $path_of_elastic_search_directory/elasticsearch.yml


#after adding above lines in elasticsearch.yml restart the elasticsearch service
sudo systemctl restart elasticsearch

#check previous command working fine or not, if not than exit from the script
if [ $? -ne 0 ]; then
  #The previous command failed, so exit the script
  exit 1
fi


#setup the repository
curl -XPUT "http://$host:9200/_snapshot/$repo_name?pretty" -H "Content-Type: application/json" -d'
{
  "type": "fs",
  "settings": {
        "location": "'"$dir"'/'"$final_es_backup_folder"'/'"$repo_name"'"
  }
}'


#move to directory where all the scripts present
cd $pwd



# Declare an empty array
my_array=()

# Read the temp file as a single string
IFS=" " read -ra words < <(tr '\n' ' ' < $pwd/temp.txt)
my_array=( "${words[@]}" )


#Delete all the indices which are present in a temp file
for index in "${my_array[@]}"; do
        curl -XDELETE 'http://'"$host"':9200/'"$index"'';
done


echo "These are the indices which are going to restore:"
#Print the array

for index in "${my_array[@]}"; do
  echo "$index"
done

#restore all indices present in a snapshot
for index in "${my_array[@]}";
do
        curl -X POST "http://$host:9200/_snapshot/$repo_name/$snapshot_name/_restore?pretty" -H 'Content-Type: application/json' -d'
        {
                "indices": "'"$index"'"
        }'
done

#remove added line from elastic search yaml
sudo sed -i '$d' $path_of_elastic_search_directory/elasticsearch.yml

#restart the elastic search service
sudo systemctl restart elasticsearch

#move to the directory where final_es_backup_folder is present
cd $dir

#Delete the final folder
sudo rm -rf $final_es_backup_folder


