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

##location this script file will be stored and run from
#floowing line is a sample
#scriptDir="Documents/Scripts/TotK Save Scripts"

##SMB share and path to where save and cache files are stored
#smbShare="//10.1.1.100/Software/"
#smbSavePath="Gaming\Switch\Saves\TotK"

#the following line loads variables from the config file
. ./TotKScripts.config

#color
Red=$'\e[1;31m'
Yellow=$'\e[1;33m'
Green=$'\e[1;32m'
Blue=$'\e[1;34m'
Endcolor=$'\e[0m'

cd ~/"$scriptDir"
ls -a
smbclient $smbShare -A ~/"$scriptDir"/.smbauth.txt -c 'prompt OFF; recurse ON; cd '$smbSavePath'\save\slot_02\; get progress.sav'
oldPlayTimeTotal=$(od progress.sav -N 4 -t u8 -A n -j 0x0003b8ec | tr -d ' ')
rm progress.sav

cd ~/$yuzuSaveDir/slot_02
newPlayTimeTotal=$(od progress.sav -N 4 -t u8 -A n -j 0x0003b8ec | tr -d ' ')

function convertSecs {
 ((h=${1}/3600))
 ((m=(${1}%3600)/60))
 ((s=${1}%60))
 printf "%02d:%02d:%02d\n" $h $m $s
}

function copyFiles {
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

oldPlayTimeHMS=$(convertSecs $oldPlayTimeTotal)
newPlayTimeHMS=$(convertSecs $newPlayTimeTotal)

shopt -s nocasematch

clear

if [[ $newPlayTimeTotal -gt $oldPlayTimeTotal ]]
then
    echo "Play time of the local Save File is more than the Save File on the server -- Server:$Green$oldPlayTimeHMS$Endcolor Local:$Green$newPlayTimeHMS$Endcolor"
    echo "Are you sure you want to copy files from share? (y/N)"
    read confirmation
    if [[ $confirmation == 'Y' ]]
    then
        echo $Blue""
        copyFiles
        echo ""$Endcolor
    else
        echo $quitMsg
        echo ""$Endcolor
        exit
    fi
elif  [[ $oldPlayTimeTotal -gt $newPlayTimeTotal ]]
then
    echo $Red"Play time of the local Save File is less than the Save File on the server$Endcolor -- Server:$Red$oldPlayTimeHMS$Endcolor Local:$Red$newPlayTimeHMS$Endcolor"
    echo "Are you sure you want to copy files from share? (y/N)"
    read confirmation
    if [[ $confirmation == 'Y' ]]
    then
        echo $Blue""
        copyFiles
        echo ""$Endcolor
    else
        echo $quitMsg
        echo ""$Endcolor
        exit
    fi
elif   [[ $oldPlayTimeTotal -eq $newPlayTimeTotal ]]
then
    echo "Play time of the local Save File is the same as the Save File on the server -- Server:$Yellow$oldPlayTimeHMS$Endcolor Local:$Yellow$newPlayTimeHMS$Endcolor"
    echo "Are you sure you want to copy files from share? (y/N)"
    read confirmation
    if [[ $confirmation == 'Y' ]]
    then
        echo $Blue""
        copyFiles
        echo ""$Endcolor
    else
        echo $Red$quitMsg
        echo ""$Endcolor
        exit
    fi
fi
