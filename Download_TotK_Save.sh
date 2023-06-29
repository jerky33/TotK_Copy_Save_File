#!/bin/bash

#Note: SMB Client uses a text file in the same folder as the script named .smbauth.txt and uses the following format (domain is optional)
#username = <value>
#password = <value>
#domain = <value>

# To find the Yuzu instance ID right click the game in Yuzu and 'Open Save Data Location', and the insance ID will be up one directory
# This first section looks for a TotK Save folder and if multiple are found it will offer an option to pich which instance to update.
totkLookup=( $(find ~/.local/share/yuzu/nand/user/save -name "0100F2C0115B6000") )

function displaySingle {
    yuzuInst=$(basename $(dirname $totkLookup))
    echo $yuzuInst
}

function displayMultiple {
    itemNum=0
    for i in ${totkLookup[@]}
    do
    yuzuInst=$(basename $(dirname $i))
    echo $yuzuInst \[$itemNum\]
    ((itemNum=$itemNum+1))
    done
    ((itemNum=$itemNum-1))
}

function selectSaveInst {
    echo "Choose the save file folder you would like to copy"
    echo "Valid choices are 0-$itemNum"
    read saveInstNum
    #echo $saveInstNum

    if [ ! -z ${totkLookup[$saveInstNum]} ] && [[ $saveInstNum =~ ^[0-9]+$ ]]
    then
        yuzuInst=$(basename $(dirname ${totkLookup[$saveInstNum]}))
        echo $yuzuInst
    else
        echo "That selection is invalid, please choose 0-$itemNum"
        displayMultiple
        selectSaveInst
    fi
}


if [ -z ${totkLookup[1]} ]
then
    echo "Only one Save Folder instance found"
    displaySingle
else
    echo "Multiple Save Folder instances found"
    displayMultiple
    selectSaveInst
fi

yuzuSaveDir=".local/share/yuzu/nand/user/save/0000000000000000/$yuzuInst/0100F2C0115B6000"
yuzuCacheDir=".local/share/yuzu/nand/user/save/cache/0000000000000000/"
quitMsg="File Copy Aborted"

#location this script file will be stored and run from
scriptDir="Documents/Scripts"

##location this script file will be stored and run from
#scriptDir="Documents/Scripts"

##location that save file backups will be kept, these are used in the event that an unwanted save file overwrites the active files
#backupPath="Documents/Gaming/TotK Saves"

##SMB share and path to where save and cache files are stored
#smbShare="//10.0.1.243/Software/"
#smbSavePath="Gaming\Switch\Saves\TotK\save"
#smbCachePath="Gaming\Switch\Saves\TotK\cache"

#the following line loads variables from the config file
. ./TotKScripts.config

#color
Red=$'\e[1;31m'
Yellow=$'\e[1;33m'
Green=$'\e[1;32m'
Blue=$'\e[1;34m'
Endcolor=$'\e[0m'

cd ~/$scriptDir
smbclient $smbShare -A ~/$scriptDir/.smbauth.txt -c 'prompt OFF; recurse ON; cd '$smbSavePath'\slot_02\; get progress.sav'
newPlayTimeTotal=$(od progress.sav -N 4 -t u8 -A n -j 0x0003b8ec | tr -d ' ')
rm progress.sav

cd ~/$yuzuSaveDir/slot_02
oldPlayTimeTotal=$(od progress.sav -N 4 -t u8 -A n -j 0x0003b8ec | tr -d ' ')

function convertSecs {
 ((h=${1}/3600))
 ((m=(${1}%3600)/60))
 ((s=${1}%60))
 printf "%02d:%02d:%02d\n" $h $m $s
}

function copyFiles {
clear
#Create backup folders if the are not present
if [ ! -d ~/"$backupPath"/savebkp1 ]; then mkdir ~/"$backupPath"/savebkp1; fi
if [ ! -d ~/"$backupPath"/savebkp2 ]; then mkdir ~/"$backupPath"/savebkp2; fi
if [ ! -d ~/"$backupPath"/savebkp3 ]; then mkdir ~/"$backupPath"/savebkp3; fi
if [ ! -d ~/"$backupPath"/savebkp4 ]; then mkdir ~/"$backupPath"/savebkp4; fi
if [ ! -d ~/"$backupPath"/savebkp5 ]; then mkdir ~/"$backupPath"/savebkp5; fi
if [ ! -d ~/"$backupPath"/save ]; then mkdir ~/"$backupPath"/save; fi
if [ ! -d ~/"$backupPath"/cachebkp1 ]; then mkdir ~/"$backupPath"/cachebkp1; fi
if [ ! -d ~/"$backupPath"/cachebkp2 ]; then mkdir ~/"$backupPath"/cachebkp2; fi
if [ ! -d ~/"$backupPath"/cachebkp3 ]; then mkdir ~/"$backupPath"/cachebkp3; fi
if [ ! -d ~/"$backupPath"/cachebkp4 ]; then mkdir ~/"$backupPath"/cachebkp4; fi
if [ ! -d ~/"$backupPath"/cachebkp5 ]; then mkdir ~/"$backupPath"/cachebkp5; fi
if [ ! -d ~/"$backupPath"/cache ]; then mkdir ~/"$backupPath"/cache; fi

cd ~/$yuzuSaveDir
rm -rf ~/"$backupPath"/savebkp5/
mv ~/"$backupPath"/savebkp4/ ~/"$backupPath"/savebkp5/
mv ~/"$backupPath"/savebkp3/ ~/"$backupPath"/savebkp4/
mv ~/"$backupPath"/savebkp2/ ~/"$backupPath"/savebkp3/
mv ~/"$backupPath"/savebkp1/ ~/"$backupPath"/savebkp2/
mv ~/"$backupPath"/save/ ~/"$backupPath"/savebkp1/
mkdir ~/"$backupPath"/save/
cp -r * ~/"$backupPath"/save/
rm -r *
cd ~/$yuzuCacheDir
rm -rf ~/"$backupPath"/cachebkp5/
mv ~/"$backupPath"/cachebkp4/ ~/"$backupPath"/cachebkp5/
mv ~/"$backupPath"/cachebkp3/ ~/"$backupPath"/cachebkp4/
mv ~/"$backupPath"/cachebkp2/ ~/"$backupPath"/cachebkp3/
mv ~/"$backupPath"/cachebkp1/ ~/"$backupPath"/cachebkp2/
mv ~/"$backupPath"/cache/ ~/"$backupPath"/cachebkp1/
mkdir ~/"$backupPath"/cache/
cp -r * ~/"$backupPath"/cache/
rm -r *

cd ~/$yuzuSaveDir
smbclient $smbShare -A ~/$scriptDir/.smbauth.txt -c 'prompt OFF; recurse ON; cd '$smbSavePath'; mget *'
cd ~/$yuzuCacheDir
smbclient $smbShare -A ~/$scriptDir/.smbauth.txt -c 'prompt OFF; recurse ON; cd '$smbCachePath'; mget *'

}

newPlayTimeHMS=$(convertSecs $newPlayTimeTotal)
oldPlayTimeHMS=$(convertSecs $oldPlayTimeTotal)

shopt -s nocasematch

clear

if [[ $newPlayTimeTotal -gt $oldPlayTimeTotal ]]
then
    echo "Play time of the Save File on the server is more than the local Save File -- Server:$Green$newPlayTimeHMS$Endcolor Local:$Green$oldPlayTimeHMS$Endcolor"
    echo "Are you sure you want to copy files from share? (y/N)"
    read confirmation
    if [[ $confirmation == 'Y' ]]
    then
        echo $Blue""
        copyFiles
    else
        echo $quitMsg
        exit
    fi
elif  [[ $oldPlayTimeTotal -gt $newPlayTimeTotal ]]
then
    echo $Red"Play time of the Save File on the server is less than the local Save File$Endcolor -- Server:$Red$newPlayTimeHMS$Endcolor Local:$Red$oldPlayTimeHMS$Endcolor"
    echo "Are you sure you want to copy files from share? (y/N)"
    read confirmation
    if [[ $confirmation == 'Y' ]]
    then
        echo $Blue""
        copyFiles
    else
        echo $quitMsg
        exit
    fi
elif   [[ $newPlayTimeTotal -eq $oldPlayTimeTotal ]]
then
    echo "Play time of the Save File on the server is the same as the local Save File -- Server:$Yellow$newPlayTimeHMS$Endcolor Local:$Yellow$oldPlayTimeHMS$Endcolor"
    echo "Are you sure you want to copy files from share? (y/N)"
    read confirmation
    if [[ $confirmation == 'Y' ]]
    then
        echo $Blue""
        copyFiles
    else
        echo $Red$quitMsg
        exit
    fi
fi
