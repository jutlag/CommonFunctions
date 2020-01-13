#Recieve the content from the paremeters, decode and store in the target file
echo ${2} | base64 -d >> ${1}
#Copy the file into the desired folder path
cp ${1} ${3}
#List files in current opath
ls
#change directory to the target path 
cd ${3}
pwd
#Show the contents of the file in the target path
cat ${1}

echo "Done"