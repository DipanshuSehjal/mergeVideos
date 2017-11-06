#!/bin/bash

# function that loops the videos and merge them.
# Algo: 
# 1. iterate over first video, extract the timeStamp from it
# 2. find the runtime of it.
# 3. iterate over next video, extract the timeStamp
# 4. Take the gap.
# 5. Make a placeholder video for that difference b/w running time of previous and difference b/w previous, and current video
# 6. Repeat the above process



declare -i num=0
echo $num
declare -i flag=0
declare -a gapArray
declare -a runArray
declare -a timeArray


timeStamp() {
	arg1=$1
  	arg2=$2
	timeArray[$arg1]=$arg2
 
}

gap(){
	arg1=$1
  	arg2=$2
	gapArray[$arg1]=$arg2

}

run(){
	arg1=$1
  	arg2=$2
	runArray[$arg1]=$arg2

}



count() {
  for f in *.avi

	do
						
							num=$(($num + 1))

							# TimeStamp
							echo "================================================="
							timeStampVid=$(stat $f| grep 'File: ' | cut -d'_' -f3,4)
							#remove .avi
							timeStampVid="$(echo $timeStampVid| cut -d'.' -f1)"
							echo "timeStamp: date & time of $num Video record: "
							echo $timeStampVid


							echo "===="
							echo "  "

							echo "date: "
							dateVid="$(echo $timeStampVid| cut -d'_' -f1)"
							echo $dateVid
							echo "===="



							echo "time: "
							timeVid="$(echo $timeStampVid| cut -d'_' -f2)"
							timeVid="${timeVid//-/':'}"
							echo $timeVid
							echo "Video recording"
							echo "===="

							# complete date: joins date and time to calculate total elapsed time
							# between dates
							echo "completeDate"
							completeDate=$dateVid' '$timeVid
							echo $completeDate
							echo "================================================"

							

							#RunTime
						
							echo "RunTime for video $num"	
							echo "="
							echo "Extracting total run time of $f" 
							runTimeVid=$(ffprobe -v quiet -of csv=p=0 -show_entries format=duration $f)
							echo "runTimeVid_$num: "
							echo $runTimeVid
							echo "========"

							#making arrays; array start from index 0
							timeStamp $(($num-1)) $dateVid' '$timeVid

							run $(($num-1)) $runTimeVid

							echo $num

							#find the gap; executes after second file
							#if [ $(($num-1)) -gt 0 ]
							if [ $(($num-1)) -gt 0 ]
							then
								echo "get Gap()"
								echo "getting difference between creation time of two video files"
								Start=$(date -d "${timeArray[$(($num-2))]}" +%s )
								Final=$(date -d "$completeDate" +%s )
								echo $Start
								echo $Final
								DIFFSECONDS=$(($Final - $Start))
								echo "diffseconds"
								echo $DIFFSECONDS


								# get the difference timeStamps and runTime of vid
								echo "Subtracting total runTimeVid from diffseconds b/w two timeStamps of videos to get the total runtime for the placeholder video"
								echo " get the difference "
								echo "${DIFFSECONDS}-${runArray[$(($num-2))]} = placeholderRunTime"
								placeholderRunTime=$(echo $DIFFSECONDS-${runArray[$(($num-2))]} | /usr/bin/bc)
								echo "placeholderRunTime"
								echo $placeholderRunTime
								echo "===="

								gap	$(($num-2)) $placeholderRunTime  			



							fi

	done
}
count

for each in "${runArray[@]}"
do
  echo "$each"
  
done

for each in "${timeArray[@]}"
do
  echo "$each"
done

#ONE ELEMENT LESS THAN TIMEARRAY
for each in "${gapArray[@]}"
do
  echo "$each"
done

num=0


sudo mkdir $(pwd)/output
sudo chmod -R 777 $(pwd)/output

# CHANGE THE RESOLUTION OF VIDEOS

# f's should be in sorted order.
for f in *.avi
do
	#num = 0
	# make placeholders
	if [ $num -lt ${#gapArray[@]} ]
	then
		ffmpeg -loop 1 -i placeholder.jpg -c:v libx264 -t ${gapArray[$num]} -pix_fmt yuv420p -vf scale=640:480 $(pwd)/output/placeholder_$num.avi
		#change in aspect ratio
		ffmpeg -i $(pwd)/output/placeholder_$num.avi -vf scale=640:480,setdar=4:3 $(pwd)/output/placeholderFinal_$num.avi
		#increment num to target next gap time
	fi

	if [ $num -eq 0 ] 
	then
		ffmpeg -i $f -i $(pwd)/output/placeholderFinal_$num.avi -filter_complex concat=n=2:v=1:a=0 -f MOV -an $(pwd)/output/output_video_$num.avi
	else
		if [ $num -eq ${#gapArray[@]} ] # to avoid clash b/w for loop detecting place/output.avi files as sampling files
		then
			ffmpeg -i $(pwd)/output/output_video_$(($num-1)).avi -i $f -filter_complex concat=n=2:v=1:a=0 -f MOV -an $(pwd)/output/output_video_final.avi
		else
			ffmpeg -i $(pwd)/output/output_video_$(($num-1)).avi -i $f -i $(pwd)/output/placeholderFinal_$num.avi -filter_complex concat=n=3:v=1:a=0 -f MOV -an $(pwd)/output/output_video_$num.avi
		fi
	fi
	# concatenation
	
	num=$(($num + 1))
	echo "num = "
	echo $num
	echo "===="

done

cd output/
find . \! -name 'output_video_final.avi' -delete
ls