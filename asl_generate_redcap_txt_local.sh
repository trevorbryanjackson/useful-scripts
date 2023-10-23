#!/usr/bin/env bash
# Assign options 
while getopts ":i:d:" opt; do
  case $opt in
    i) 
      argument=$OPTARG # session ids
      ;;
   d)
     path_to_data=$OPTARG # Project name , either MAP or TAP
      ;;
  esac
done


cd "$path_to_data"
echo "$path_to_data"
sessions=$(ls)
for session in ${sessions} ; do 
  id_folder=$(ls "$session")
  cd "$session"/"$id_folder"
  echo "$PWD"
  mkdir redcap_upload
  current_time=$(date "+%Y%m%d%H%M")
  file=redcap_upload_"$session"_asl_"$current_time".txt
  cat  indHct/asl_multiatlasv2_rois_hct.txt >> redcap_upload/asl_ind.temp
  cat  indHct/asl_multiatlasv2_rois_hct_sCoV.txt >> redcap_upload/asl_ind_scov.temp
  cat setHct/asl_multiatlasv2_rois.txt >> redcap_upload/asl_setHct.temp
  cat  setHct/asl_multiatlasv2_rois_sCoV.txt >> redcap_upload/asl_set_scov.temp
  cat  indHct_pvc/asl_multiatlasv2_rois_hct_pvc.txt >> redcap_upload/asl_ind_pvc.temp
  cat  setHct_pvc/asl_multiatlasv2_rois_pvc.txt >> redcap_upload/asl_set_pvc.temp

  cd redcap_upload/
  cat asl_ind.temp | awk -F ',' '{print $1"_hct"","$2}' >> asl_indHct.temp
  cat asl_ind_scov.temp | awk -F ',' '{print $1"_hct_scov"","$2}' >> asl_indHct_scov.temp
  cat asl_set_scov.temp | awk -F ',' '{print $1"_scov"","$2}' >> asl_setHct_scov.temp
  cat asl_ind_pvc.temp | awk -F ',' '{print $1"_hct_pvcorrected"","$2}' >> asl_indHct_pvc.temp
  cat asl_set_pvc.temp | awk -F ',' '{print $1"_pvcorrected"","$2}' >> asl_setHct_pvc.temp

  cat asl_indHct.temp asl_setHct.temp asl_indHct_pvc.temp asl_setHct_pvc.temp >> asl.temp
  # Remove all lines that have asl_diff and voxel (this info does not get recorded on redcap)
  cat  asl.temp | grep -v asl_diff | grep -v voxel > redcap_upload.temp
  # For each line (delimited by a comma), assign first value and second value to variables, enforce the second variable to have one decimal point and then paste them back together 
  cat redcap_upload.temp | while IFS='' read -r line || [[ -n "$line" ]]; do m=`echo $line | tail -c 2` ; [ $m == ',' ] && continue ; A="$(cut -d',' -f1 <<<"$line")" ; B="$(cut -d',' -f2 <<<"$line")" ; b=`printf "%.1f\n" $B` ; paste -d ","  <(printf %s "$A") <(printf %s "$b") >> redcap_final.temp ; done
  # Need more digits in the sCOV variables
  cat asl_setHct_scov.temp asl_indHct_scov.temp >> redcap_final.temp
  cat redcap_final.temp | grep -v "cingulate," | grep -v "insula," | grep -v "insula_hct" | grep -v "cingulate_hct" > $file
  # Remove the temp file 
  rm *.temp
  cd "$path_to_data"
done

