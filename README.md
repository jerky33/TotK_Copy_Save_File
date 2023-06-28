# TotK_Copy_Save_File
These are just a couple scripts I use to copy my most recemt Zelda Tears of the Kingdom save files from one compter to an SMB file server, using the Upload script, then copy the files to another computer using the Download script.
These scripts were written to work with the folder structure the Yuzu emulator uses to store game save data.
The Download script looks for a TotK save folder, if there are multiple it will give the user an option to pick the save folder they wish to update, then downloads the latest manual save file from the SMB server, and compares the time played to the latest local save and gives the user the option to proceed with the file copy or not.
The Upload script looks for a TotK save folder, if there are multiple it will give the user an option to pick the save folder they wish to upload to the SMB server, then downloads the latest manual save file from the SMB server, and compares the time played to the latest local save and gives the user the option to proceed with the file copy or not.
Both scripts make a set of backup folders of the latest five save transfers (locally for the Download script and on the SMB server for the Upload script) allowing the user to recover from an instance where they overwrite a game save inadvertantly.

Note: With regards to the sample.smbauth.txt, the user will need to rename the file '.smbauth.txt' or update the scripts to use a different file name if desired. Per the smbclient manual the line containg 'domain' is optional and can be removed if not needed.

You should only need to update the variables in the config file

The following lined contain the contents of the sample config file

\#location this script file will be stored and run from

scriptDir="Documents/Scripts/TotK Save Scripts"

\#location that save file backups will be kept, these are used in the event that an unwanted save file overwrites the active files

backupPath="Documents/Gaming/TotK Saves"

\#SMB share and path to where save and cache files are stored

smbShare="//10.1.1.100/Share/"

smbSavePath="Gaming\Switch\Saves\TotK"


