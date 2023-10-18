#!/bin/bash

fs0_path='/fs0/MAP/PROCESSED'

freewater_dirs=$(find /data/h_vmac/arched1/VMAP_Freewater_Fall2023/ -type d -name FREEWATER)

for dir in ${freewater_dirs}; do 
	mapid=$(echo $dir | awk -F'/' '{print $6}')
	epoch=$(echo $dir | awk -F'/' '{print $7}')
	session=$(echo $dir | awk -F'/' '{print $8}')
	#Removing files from fs0.
	rm -rf "$fs0_path"/"$mapid"/Brain/"$epoch"/DTI/"$session"/FREEWATER
	#Create FREEWATER dir
	mkdir -p "$fs0_path"/"$mapid"/Brain/"$epoch"/DTI/"$session"/FREEWATER/ROIstats
	#Copy over files to keep.
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
done

