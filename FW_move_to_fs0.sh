#!/bin/bash

fs0_path='/fs0/MAP/PROCESSED'
freewater_dirs=$(find /data/h_vmac/arched1/VMAP_Freewater_Fall2023/ -type d -name FREEWATER)

for dir in ${freewater_dirs}; do 
	mapid=$(echo $dir | awk -F'/' '{print $6}')
	epoch=$(echo $dir | awk -F'/' '{print $7}')
	session=$(echo $dir | awk -F'/' '{print $8}')
	session_dir="/data/h_vmac/arched1/VMAP_Freewater_Fall2023/$mapid/$epoch/$session/OUTPUTS/FREEWATER"

	# Format the labels correctl adn generate redcap upload txt files 
	rm "$session_dir"/ROIstats/*_freewater_roi.txt
	tr '[:upper:]' '[:lower:]' < "$session_dir"/ROIstats/ALLtracts_Pasternak.csv > "$session_dir"/ROIstats/all_tracts.temp
	sed -i s'/gyrus_//g ; s/_sulcus_/_/g ; s/_lobule_/_/g ; s/-/_/g' "$session_dir"/ROIstats/all_tracts.temp
	sed -i 's/_nan//g' "$session_dir"/ROIstats/all_tracts.temp
	sed -i 's/pasternak_//g' "$session_dir"/ROIstats/all_tracts.temp
	sed -i 's/syn_//g' "$session_dir"/ROIstats/all_tracts.temp
	sed -i 's/_final//g' "$session_dir"/ROIstats/all_tracts.temp
	sed -i 's/_corr/_corrected/g' "$session_dir"/ROIstats/all_tracts.temp
	sed -i 's/fw_//g' "$session_dir"/ROIstats/all_tracts.temp
	sed -i 's/_fw,/,/g' "$session_dir"/ROIstats/all_tracts.temp
	cat "$session_dir"/ROIstats/all_tracts.temp | while read line; do 
		if [[ "$line" == *_ad,* ]] 
			then n=$(echo "$line" | sed 's/_ad,/,/g')  
			echo "dti_fw_ants_ad_$n"  >> "$session_dir"/ROIstats/"$mapid"_"$session"_freewater_roi.txt 
		elif [[ "$line" == *_md,* ]] 
			then n=$(echo "$line" | sed 's/_md,/,/g')  
			echo "dti_fw_ants_md_$n"  >> "$session_dir"/ROIstats/"$mapid"_"$session"_freewater_roi.txt
		elif [[ "$line" == *_rd,* ]]
			then n=$(echo "$line" | sed 's/_rd,/,/g')  
			echo "dti_fw_ants_rd_$n"  >> "$session_dir"/ROIstats/"$mapid"_"$session"_freewater_roi.txt
		elif [[ "$line" == *_fa,* ]]
			then n=$(echo "$line" | sed 's/_fa,/,/g') 
			echo "dti_fw_ants_fa_$n"  >> "$session_dir"/ROIstats/"$mapid"_"$session"_freewater_roi.txt 
		else echo "dti_fw_ants_$line" >> "$session_dir"/ROIstats/"$mapid"_"$session"_freewater_roi.txt  
		fi 
	done
	rm "$session_dir"/ROIstats/all_tracts.temp
	x=$(date)
	printf "\nFREEWATER ROI END: %s\n\n" "$x"

	# Removing files from fs0.
	rm -rf "$fs0_path"/"$mapid"/Brain/"$epoch"/DTI/"$session"/FREEWATER

	# Create FREEWATER dir
	mkdir -p "$fs0_path"/"$mapid"/Brain/"$epoch"/DTI/"$session"/FREEWATER/ROIstats

	# Copy over files to keep.
	rsync "$dir"/SyN_Pasternak_FW.nii.gz "$fs0_path"/"$mapid"/Brain/"$epoch"/DTI/"$session"/FREEWATER
	rsync "$dir"/SyN_Pasternak_FW_corr_FA.nii.gz "$fs0_path"/"$mapid"/Brain/"$epoch"/DTI/"$session"/FREEWATER
	rsync "$dir"/SyN_Pasternak_FW_corr_AD.nii.gz "$fs0_path"/"$mapid"/Brain/"$epoch"/DTI/"$session"/FREEWATER
	rsync "$dir"/SyN_Pasternak_FW_corr_RD.nii.gz "$fs0_path"/"$mapid"/Brain/"$epoch"/DTI/"$session"/FREEWATER
	rsync "$dir"/SyN_Pasternak_FW_corr_MD.nii.gz "$fs0_path"/"$mapid"/Brain/"$epoch"/DTI/"$session"/FREEWATER
	rsync "$dir"/Pasternak_FW.nii.gz "$fs0_path"/"$mapid"/Brain/"$epoch"/DTI/"$session"/FREEWATER
	rsync "$dir"/Pasternak_FW_corr_FA.nii.gz "$fs0_path"/"$mapid"/Brain/"$epoch"/DTI/"$session"/FREEWATER
	rsync "$dir"/Pasternak_FW_corr_AD.nii.gz "$fs0_path"/"$mapid"/Brain/"$epoch"/DTI/"$session"/FREEWATER
	rsync "$dir"/Pasternak_FW_corr_RD.nii.gz "$fs0_path"/"$mapid"/Brain/"$epoch"/DTI/"$session"/FREEWATER
	rsync "$dir"/Pasternak_FW_corr_MD.nii.gz "$fs0_path"/"$mapid"/Brain/"$epoch"/DTI/"$session"/FREEWATER
	rsync "$dir"/ROIstats/ALLtracts_Pasternak.csv "$fs0_path"/"$mapid"/Brain/"$epoch"/DTI/"$session"/FREEWATER/ROIstats
	rsync "$dir"/ROIstats/"$mapid"_"$session"_freewater_roi.txt "$fs0_path"/"$mapid"/Brain/"$epoch"/DTI/"$session"/FREEWATER/ROIstats
	chgrp -R h_vmac "$fs0_path"/"$mapid"/Brain/"$epoch"/DTI/"$session" 
	chmod -R 775 "$fs0_path"/"$mapid"/Brain/"$epoch"/DTI/"$session" 
done

