#!/bin/bash

#Note: SMB Client uses a text file in the same folder as the script named .smbauth.txt and uses the following format (domain is optional)
#username = <value>
#password = <value>
#domain = <value>

# To find the Yuzu instance ID right click the game in Yuzu and 'Open Save Data Location', and the insance ID will be up one directory
# Fedora-PC Yuzu Insance D452A88EF188623E13860EABEC653E27
# Steam Deck Yuzu Instance BC5EDEC815A19E408C512754198A480F
yuzuInst=D452A88EF188623E13860EABEC653E27
yuzuSaveDir=".local/share/yuzu/nand/user/save/0000000000000000/$yuzuInst/0100F2C0115B6000"
yuzuCacheDir=".local/share/yuzu/nand/user/save/cache/0000000000000000/"
backupPath="Documents/Gaming/TotK Saves"
quitMsg="File Copy Aborted"

#cd ~/.local/share/yuzu/nand/user/save/0000000000000000/$yuzuInst/0100F2C0115B6000/

#location this script file will be stored and run from
scriptDir="Documents/Scripts/TotK Save Scripts"

#SMB share and path to where save and cache files are stored
smbShare="//10.0.1.243/Software/"
smbSavePath="Gaming\Switch\Saves\TotK"


#color

Red=$'\e[1;31m'
Yellow=$'\e[1;33m'
Green=$'\e[1;32m'
Blue=$'\e[1;34m'
Endcolor=$'\e[0m'

cd ~/"$scriptDir"
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
