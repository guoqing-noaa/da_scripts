#!/bin/sh

export VERBOSE=YES
export OMP_STACKSIZE=256M
charnanal="control"
pushd ${datapath2}

fh=${FHMIN}
while [ $fh -le $FHMAX ]; do
   charfhr="fhr"`printf %02i $fh`
   
   echo "recenter ensemble perturbations"
   filename_meanin=sfg_${analdate}_${charfhr}_ensmean
   filename_meanout=sfg_${analdate}_${charfhr}_${charnanal}.chgres
   filenamein=sfg_${analdate}_${charfhr}
   filenameout=sfgr_${analdate}_${charfhr}
   
   export PGM="${execdir}/recenterens_ncio.x $filenamein $filename_meanin $filename_meanout $filenameout $nanals $recenter_ensmean_wgt $recenter_control_wgt"
   errorcode=0
   ${enkfscripts}/runmpi
   status=$?
   if [ $status -ne 0 ]; then
    errorcode=1
   fi
   
   if [ $errorcode -eq 0 ]; then
      echo "yes" > ${current_logdir}/recenter.log
   else
      echo "no" > ${current_logdir}/recenter.log
      exit 1
   fi
   
   # rename files.
   /bin/mv -f $filename_meanin  ${filename_meanin}.orig
   /bin/cp -f $filename_meanout $filename_meanin
   nanal=1
   while [ $nanal -le $nanals ]; do
      charnanal_tmp="mem"`printf %03i $nanal`
      analfiler=sfgr_${analdate}_${charfhr}_${charnanal_tmp}
      analfile=sfg_${analdate}_${charfhr}_${charnanal_tmp}
      if [ -s $analfiler ]; then
         /bin/mv -f $analfile ${analfile}.orig
         /bin/mv -f $analfiler $analfile
         status=$?
         if [ $status -ne 0 ]; then
          errorcode=1
         fi
      else
         echo "no" > ${current_logdir}/recenter.log
         exit 1
      fi
      nanal=$((nanal+1))
   done
   
   if [ $errorcode -eq 0 ]; then
      echo "yes" > ${current_logdir}/recenter.log
   else
      echo "error encountered, copying original files back.."
      echo "no" >! ${current_logdir}/recenter.log
      # rename files back
      /bin/mv -f ${filename_meanin}.orig  ${filename_meanin}
      nanal=1
      while [ $nanal -le $nanals ]; do
         charnanal_tmp="mem"`printf %03i $nanal`
         analfile=sfg_${analdate}_${charfhr}_${charnanal_tmp}
         /bin/mv -f ${analfile}.orig ${analfile}
         nanal=$((nanal+1))
      done
      exit 1
   fi
   
   fh=$((fh+FHOUT))
done # next time
popd

exit 0
