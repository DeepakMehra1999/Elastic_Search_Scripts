#!/bin/bash

#present working directory
pwd=$(pwd)

#take variable values from an input file
source ./elastic_search_input_file.txt

#create the repository in elasticsearch directory
sudo mkdir -p $dir/$folder_name/$repo_name

#assign necessary permissions to repository
sudo chown -R elasticsearch. $dir/$folder_name/$repo_name

#add these lines in elasticsearch.yml before taking backup
#echo "node.name: 'node-1'" >> $path_of_elastic_search_directory/elasticsearch.yml
#echo "cluster.initial_master_nodes: ['node-1']" >> $path_of_elastic_search_directory/elasticsearch.yml
echo "path.repo: ['$dir/$folder_name/$repo_name']" >> $path_of_elastic_search_directory/elasticsearch.yml


#after adding above lines in elasticsearch.yml restart the elasticsearch service
sudo systemctl restart elasticsearch

#check previous command working fine or not, if not than exit from the script
if [ $? -ne 0 ]; then
  #The previous command failed, so exit the script
  exit 1
fi

#Use below variable for color coding
reset=`tput sgr0`
green=`tput setaf 2`
blue=`tput setaf 4`
#sudo systemctl status elasticsearch

#setup the repository
echo "***************Creating Repository************* "
curl -XPUT "http://$host:9200/_snapshot/$repo_name?pretty" -H "Content-Type: application/json" -d'
{
  "type": "fs",
  "settings": {
        "location": "'"$dir"'/'"$folder_name"'/'"$repo_name"'"
  }
}'

echo -e "\n*************$repo_name repository created Successfully****************"

#check repository is properly set or not
curl -XGET "http://$host:9200/_snapshot/_all?pretty"

echo -e "\n************List of Indices present***********"

#check the number of indices present
curl -XGET "http://$host:9200/_cat/indices"

echo -e "\n***************Start taking Backup************"

#take backup of elasticsearch cluster
curl -XPUT "http://$host:9200/_snapshot/$repo_name/$snapshot_name?wait_for_completion=true"


#check backup created or not
curl -XGET "http://$host:9200/_snapshot/$repo_name/$snapshot_name?pretty"

#Remove the added lines in elasticsearch.yml
sudo sed -i '$d' $path_of_elastic_search_directory/elasticsearch.yml

#move to the directory where repository created
cd $dir/$folder_name

#create a tar file of this backup and rename it with today's timestamp
tar -cf $repo_name'_'$(date +"%Y-%m-%d_%H-%M-%S")'.tar' $repo_name/

#store the tart file path in variable named as latest_tar
latest_tar=$(ls -t $dir/$folder_name/*.tar | head -1)


#store all the indices present in a backup to an array
#move to present working directory
cd $pwd

#run another script to store the indices in a temp file of above backup
bash elastic_search_script_to_store_indices.sh

#install the sshpass
sudo rpm -i $pwd/sshpass*.rpm


#transfer your backup tar file to the 2nd server
sudo sshpass -p "$host_password_of_server2" scp -oStrictHostKeyChecking=no -r $latest_tar "$host_user_of_server2"@"$host_ip_of_server2":$path_where_you_want_to_move_backup

#transfer the temp file to the 2nd server in a directory where restore script is present
sudo sshpass -p "$host_password_of_server2" scp -oStrictHostKeyChecking=no -r $pwd/temp.txt "$host_user_of_server2"@"$host_ip_of_server2":$path_of_scripts_present_on_other_server

#if value of backup location is S3 in an input file, push the backup to S3 bucket else store it in a local file system
if [ "$backup_location" == 'S3' ];then
        bash elastic_search_backup_push_to_S3_script.sh
        rm -rf $dir/$folder_name/*
        #rm -rf $dir/$final_gitlab_folder'_'$(date +"%d-%m-%Y")
elif [ "$backup_location" == 'LF' ];then
        #Remove the repository from the cluster to avoid repository exception
        echo "**********Deleting Repository*********"
        curl -X DELETE "http://$host:9200/_snapshot/$repo_name?pretty"
        echo -e "\n**********Clearing backup files*******"
        echo -e "\nCheck $path_where_you_want_to_move_backup location in 2nd Server"
        echo "Backup files securely transferred to another server in '$path_where_you_want_to_move_backup'"
        echo -e "\n${green}*******Backup Task is Completed*******${reset}"
else
        echo "Input the valid backup location"
fi


rm -rf $dir/$folder_name/*
rm -rf $pwd/temp.txt

