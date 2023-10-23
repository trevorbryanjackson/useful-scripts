#!/bin/bash
project=$1
logoutputdir=$2
compdir=$3

list=$(ls $compdir)
if [[ -f $list ]]; then
  	echo "Input is a hashlist" ;
  	hash_list=$list
else
  	echo "Input is not a hashlist"
	echo "$PWD"
  # Generate a sub list from Neuroimaging Link using the sessions provided
	if [[ ${project} == 'MAP' ]]; then 
  		echo "MAP project"
		main_list=$(find /fs0/repos/tools/hash_lists/ -maxdepth 1 -type f -iname "VMAP*ScansAcquired*.csv")
	elif [[ ${project} == 'TAP' ]]; then 
  		main_list=$(find /fs0/repos/tools/hash_lists/ -maxdepth 1 -type f -iname "TAP*ScansAcquired*.csv")
  		echo "TAP project"
	fi
	echo $main_list
	head -n 1 "$main_list"  > subset.csv
  	for i in $list; do
    	match=$(cat $main_list | grep -e "$i")
    if [[ -z "$match" ]] ; then 
     	error ""$i" not in Scans Acquired hashlist\n" 
    else 
      	echo "$match" >> subset.csv
    fi
  	done
  	hash_list=$PWD/subset.csv
  	echo $hash_list
fi
# Find out column numbers for sessions, map_ids and epoch 
sess_col=$(awk -v RS=',' '/session_id/{print NR; exit}' $hash_list)
epoch_col=$(awk -v RS=',' '/epoch/{print NR; exit}' $hash_list)
if [[ $project == 'MAP' ]]; then 
  id_col=$(awk -v RS=',' '/map_id/{print NR; exit}' $hash_list)
elif [[ $project == 'TAP' ]]; then 
  id_col=$(awk -v RS=',' '/vmac_id/{print NR; exit}' $hash_list)
fi
# Read a hash list from the second line (ignore header)
tail -n +2 $hash_list | while read line
do
	map=$(echo $line | awk -v m="$id_col" -F ',' '{print $m}')
	session=$(echo "$line" | awk -v s="$sess_col" -F ',' '{print $s}')
	epoch=$(echo "$line" | awk -v e="$epoch_col" -F ',' '{print $e}')
	if [[ "$epoch" -eq "0" ]] ; then 
		epoch="BH" 
	fi
	printf "===========\n$project: $map, SESSION: $session, Epoch: ${epoch}\n"  >> ${logoutputdir}/differencenew.txt
	local_ru_dir=$(find /data/h_vmac/jacksotb/asl_project/${project}_data_freeze/${session}/${map}/redcap_upload -type d )
	#printf "Local folder: $local_ru_dir" >> $logoutputdir/differencenew.txt
	localru=$(find ${local_ru_dir} -type f -name "redcap_upload*.txt")
    if [[ `ls $localru  | wc -l` -gt 1 ]] ; then
        echo "Too many local files for $session - choosing most recent.\n"
    	localru=$(find ${local_ru_dir} -type f -name "redcap_upload*.txt" | tail -n 1) 
    fi
    printf "Local file: $localru\n" >> ${logoutputdir}/differencenew.txt
	fs0_ru_dir=$(find /fs0/${project}/PROCESSED/${map}/Brain/EPOCH${epoch}/ASL/${session}/redcap_upload -type d )
	#echo $fs0_ru_dir >> $logoutputdir/differencenew.txt
	fs0ru=$(find ${fs0_ru_dir} -type f -name "redcap_upload*.txt")
    if [[ `ls $fs0ru  | wc -l` -gt 1 ]] ; then
        echo "Too many files on fs0 for $session - choosing most recent.\n"
        fs0ru=$(find ${fs0_ru_dir} -type f -name "redcap_upload*.txt" | tail -n 1)
   	fi
	printf "fs0 file: $fs0ru\n" >> ${logoutputdir}/differencenew.txt 

	diff -y --suppress-common-lines $localru $fs0ru >> ${logoutputdir}/differencenew.txt
	printf "\n" >> ${logoutputdir}/differencenew.txt
done