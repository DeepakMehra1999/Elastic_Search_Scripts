#! /bin/bash

#Use source to import variables from an input file
source ./elastic_search_input_file.txt

#present working directory
pwd=$(pwd)

#Use below code, it will automatically convert Yes/yes to yes
backup=$Backup
Backup=${backup,,}

pull=$Pull
Pull=${pull,,}

restore=$Restore
Restore=${restore,,}


#Use below statements to execute the scripts according to values in an input file
if [ "$Backup" == "yes" ];then
        sudo bash elastic_search_backup_script.sh
elif [ "$Pull" == "yes" ];then
        sudo bash elastic_search_
elif [ "$Restore" == "yes" ];then
        sudo bash elastic_search_restore_script.sh
else
        echo "Please specify the valid input in an input file"
fi

#Remove values of below lines from an input file
#sed -i 's/Backup=.*/Backup=/g' $pwd/gitlab_input_file.txt
#sed -i 's/Pull=.*/Pull=/g' $pwd/gitlab_input_file.txt
#sed -i 's/Restore=.*/Restore=/g' $pwd/gitlab_input_file.txt
#sed -i 's/backup_location=.*/backup_location=/g' $pwd/gitlab_input_file.txt

