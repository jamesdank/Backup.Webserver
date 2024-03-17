#!/bin/bash
##############################################################################################
# Config FTP Backup ##########################################################################
ftp_server="ftp.example.com"
ftp_username="username"
ftp_password="password"
ftp_temp_dir=""
##############################################################################################
# Config mySQL Backup ########################################################################
db_username="root"
db_password=""
##############################################################################################
# Config Local Backup ########################################################################
local="/home/$USER/backups/"
##############################################################################################
# Config Exterrnal Backup ####################################################################
external="/media/$USER/backups/"
##############################################################################################
# Config Encryption ##########################################################################
encryption="AES256"
passphrase="_6b;XZ,M1<xf4cJr7\7}84wW"
##############################################################################################
# Decrypt File Example #######################################################################
# echo <passphrase> | gpg --batch --yes --passphrase-fd 0 backup-2024-03-16_205036.tar.gz.gpg
##############################################################################################

date="$(date +%Y-%m-%d_%H%M%S)"

output="backup-$date.tar.gz"

# Change Directory Depending on Options
if [ -n "${local}" ] 
then
    mkdir -p "${local}backup-${date}"

    cd "${local}backup-${date}"
elif [ -n "${external}" ] 
then
    mkdir -p "${external}backup-${date}"

    cd "${external}backup-${date}"
elif [ -n "${ftp_temp_dir}" ] 
then
    mkdir -p "${ftp_temp_dir}backup-${date}"

    cd "${ftp_temp_dir}backup-${date}"
else 
   echo "No Directory Available to Create Backups."

   exit 0
fi

function backup_directories {
    # Backup Directories
    declare -A folders=(
        ["folder1"]="folder1/"
        ["www"]="var/www/html/"
    );

     # Create Directory Backups
    for key in ${!folders[@]}
    do
        tar -czf "${key}.tar.gz" -C / "${folders[${key}]}"
    done

    if [ -n $passwdfile ] && [ -n $encryption ]
    then 
        output=$output".gpg"

        # Combine Compressed Directories into One Compressed File and Encrypt with GPG
        tar -cz * | gpg --passphrase "$passphrase" -c --no-symkey-cache --cipher-algo "$encryption" --batch -o "$output"
    fi
}

# Backup Databases Check
if [ -n "${db_username}" ]
then
    mysqldump=$(whereis mysqldump | sed 's|mysqldump: ||g')

    # Backup Databases
    declare -a databases=(
        'database1'
        'database2'
        'database3'
    );

    # Create Database Backups
    for db in ${databases[@]}
    do
        $mysqldump -u $db_username -p "--password=$db_password" "$db" > "db-$db.sql"
    done
fi

# Backup Local Directories Check
if [ -n "${local}" ]
then
    backup_directories
fi

# Backup External Directories Check
if [ -n "${external}" ] && [ -n "${local}" ] 
then
    mkdir -p "${external}backup-${date}"

    cp $output ${external}backup-${date}
elif [ -n "${external}" ]
then
    backup_directories
else 
   echo ""
fi

# Upload Compressed Encrypted File to FTP Server Check
if [ -n "${ftp_server}" ] && [ -z "${local}" ] && [ -z "${external}" ]
then
    backup_directories

    curl -T "$output" -u "$ftp_username:$ftp_password" "$ftp_server"
elif [ -n "${ftp_server}" ]
then
    curl -T "$output" -u "$ftp_username:$ftp_password" "$ftp_server"
else 
    echo ""
fi

# Delete All Files Except Compressed/Encrypted One
shopt -s extglob

rm !("$output")
