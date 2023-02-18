#!/bin/bash

#importing variables from an input file
source ./elastic_search_input_file.txt

#store the recent tar file path of gitlab backup in a variable
recent_tar=$(ls -t $dir/$folder_name/*.tar | head -1)

#separate filename from file path
file_name=$(basename "$recent_tar")

AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} /usr/local/bin/aws --region us-east-2 s3 cp $recent_tar s3://$Bucket_Name/$Folder_Name
