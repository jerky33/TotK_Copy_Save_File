#!/bin/bash

#Note: SMB Client uses a text file in the same folder as the script named .smbauth.txt and uses the following format (domain is optional)
#username = <value>
#password = <value>
#domain = <value>

# To find the Yuzu instance ID right click the game in Yuzu and 'Open Save Data Location', and the insance ID will be up one directory
# This first section looks for a TotK Save folder and if multiple are found it will offer an option to pich which instance to upload to the SMB server.
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

#the following line loads variables from the config file
. ~/Documents/Scripts/TotK\ Save\ Scripts/TotKScripts.config

#color
Red=$'\e[1;31m'
Yellow=$'\e[1;33m'
Green=$'\e[1;32m'
Blue=$'\e[1;34m'
Endcolor=$'\e[0m'

cd ~/"$scriptDir"
ls -a
smbclient $smbShare -A ~/"$scriptDir"/.smbauth.txt -c 'prompt OFF; recurse ON; cd '$smbSavePath'\save\slot_02\; get progress.sav'
serverPlayTimeTotal=$(od ~/"$scriptDir"/progress.sav -N 4 -t u8 -A n -j 0x0003b8ec | tr -d ' ')
rm progress.sav

cd ~/$yuzuSaveDir/slot_02
localPlayTimeTotal=$(od progress.sav -N 4 -t u8 -A n -j 0x0003b8ec | tr -d ' ')

function convertSecs {
 ((h=${1}/3600))
 ((m=(${1}%3600)/60))
 ((s=${1}%60))
 printf "%02d:%02d:%02d\n" $h $m $s
}

function uploadFiles {
clear
cd ~/$yuzuSaveDir
smbclient $smbShare -A ~/"$scriptDir"/.smbauth.txt -c 'prompt OFF;recurse ON; cd '$smbSavePath'; deltree savebkp5;
rename savebkp4 savebkp5; rename savebkp3 savebkp4; rename savebkp2 savebkp3; rename savebkp1 savebkp2; rename save savebkp1;
mkdir save; cd save; mput *'
cd ~/$yuzuCacheDir
smbclient $smbShare -A ~/"$scriptDir"/.smbauth.txt -c 'prompt OFF; recurse ON; cd '$smbSavePath'; deltree cachebkp5;
rename cachebkp4 cachebkp5; rename cachebkp3 cachebkp4; rename cachebkp2 cachebkp3; rename cachebkp1 cachebkp2; rename cache cachebkp1;
mkdir cache; cd cache; mput *'
}

function downloadFiles {
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
smbclient $smbShare -A ~/"$scriptDir"/.smbauth.txt -c 'prompt OFF; recurse ON; cd '$smbSavePath'\save\; mget *'
cd ~/$yuzuCacheDir
smbclient $smbShare -A ~/"$scriptDir"/.smbauth.txt -c 'prompt OFF; recurse ON; cd '$smbSavePath'\cache\; mget *'

}

serverPlayTimeHMS=$(convertSecs $serverPlayTimeTotal)
localPlayTimeHMS=$(convertSecs $localPlayTimeTotal)

shopt -s nocasematch

if [[ $localPlayTimeTotal -gt $serverPlayTimeTotal ]]
then
    fileState="more than"
elif [[ $serverPlayTimeTotal -gt $localPlayTimeTotal ]]
then
    fileState="less than"
elif [[ $serverPlayTimeTotal -eq $localPlayTimeTotal ]]
then
    fileState="the same as"
fi


clear

echo "Play time of the local Save File is $fileState the Save File on the server -- Server:$Blue$serverPlayTimeHMS$Endcolor Local:$Blue$localPlayTimeHMS$Endcolor"

echo "Would you like to Upload the local save file to the server or Download the server save file to this PC? (u/d)"
read trasferOption
if [[ $trasferOption == 'U' ]] && [[ $localPlayTimeTotal -gt $serverPlayTimeTotal ]]
then
    echo $Blue""; uploadFiles; echo ""$Endcolor
elif [[ $trasferOption == 'U' ]] && [[ $serverPlayTimeTotal -gt $localPlayTimeTotal ]]
then
    echo "You are attempting to overwrite newer files with older files, are you sure you wish to continue? (y/N)"
    read confirmation
    if [[ $confirmation == 'Y' ]]
    then
        echo $Blue""; uploadFiles; echo ""$Endcolor
    else
        echo $Red$quitMsg$Endcolor
        exit
    fi
elif [[ $trasferOption == 'D' ]] && [[ $serverPlayTimeTotal -gt $localPlayTimeTotal ]]
then
    echo $Blue""; downloadFiles; echo ""$Endcolor
elif [[ $trasferOption == 'D' ]] && [[ $localPlayTimeTotal -gt $serverPlayTimeTotal ]]
then
    echo "You are attempting to overwrite newer files with older files, are you sure you wish to continue? (y/N)"
    read confirmation
    if [[ $confirmation == 'Y' ]]
    then
        echo $Blue""; downloadFiles; echo ""$Endcolor
    else
        echo $Red$quitMsg$Endcolor
        exit
    fi
elif ([ $trasferOption == 'U' ] || [ $trasferOption == 'D' ]) && [[ $localPlayTimeTotal -eq $serverPlayTimeTotal ]]
then
    echo "You are attempting to overwrite files with the same timestamp, are you sure you wish to continue? (y/N)"
    read confirmation
    if [[ $confirmation == 'Y' ]]
    then
        if [[ $trasferOption == 'U' ]]
        then
            echo $Blue""; uploadFiles; echo ""$Endcolor
        elif [[ $trasferOption == 'D' ]]
        then
            echo $Blue""; downloadFiles; echo ""$Endcolor
        fi
    else
        echo $Red$quitMsg$Endcolor
        exit
    fi
fi


