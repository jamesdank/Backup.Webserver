#!/bin/bash

##################################################################################################
# Whatever you don't want to use leave blank
##################################################################################################
# Config Local Backup ############################################################################
local="" # Example "/home/$USER/backups/"
##################################################################################################
# Config Exterrnal Backup ########################################################################
external="" # Example "/mnt/Storage/backups/"
##################################################################################################
# Config FTP Backup ##############################################################################
ftp_server="" # Example "ftp.example.com"
ftp_username=""
ftp_password=""
ftp_temp_dir="" # Example "/home/$USER/ftp_temp" Only needed if local and external are blank
##################################################################################################
# Config mySQL Backup ############################################################################
db_username=""
db_password=""
##################################################################################################
# Config Encryption ##############################################################################
encryption="" # Example "AES256" Get algorithm options by typing "gpg --version" in terminal
passphrase=""  # Example "_6b;XZ,M1<xf4cJr7\7}84wW"
##################################################################################################
# Decrypt File Example ###########################################################################
# echo <passphrase> | gpg --batch --yes --passphrase-fd 0 backup-2024-03-16_205036.tar.gz.gpg
##################################################################################################
# Log Config #####################################################################################
log="" # Example "/home/$USER/backups/log.txt"
##################################################################################################

date="$(date +%Y-%m-%d_%H%M%S)"

output="backup-$date.tar"

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
        ["scripts"]="home/dataspy/scripts/"
    );

    # Create Directory Backups
    for key in ${!folders[@]}
    do
        if [ -n "$log" ] && [ -z "$passphrase" ] || [ -z "$encryption" ]
        then
            log_date="$(date +%Y-%m-%d)"

            start=$(date +%s)

            tar -C / -cf - "${folders[${key}]}" | gzip -9 > "${key}.tar.gz"

            end=$(date +%s)

            echo "$log_date - ${key}.tar.gz Took $(($end-$start)) seconds to compress" >> "$log"
        elif  [ -n "$log" ] && [ -n "$passphrase" ] && [ -n "$encryption" ]
        then
            log_date="$(date +%Y-%m-%d)"

            start=$(date +%s)

            tar -C / -cf - "${folders[${key}]}" | gzip -9 | gpg -v --passphrase "$passphrase" -c --no-symkey-cache --cipher-algo "$encryption" --batch -o "${key}.tar.gz.gpg"

            end=$(date +%s)

            echo "$log_date - ${key}.tar.gz.gpg Took $(($end-$start)) seconds to compress and encrypt" >> "$log"
        elif  [ -z "$log" ] && [ -n "$passphrase" ] && [ -n "$encryption" ]
        then
            tar -C / -cf - "${folders[${key}]}" | gzip -9 | gpg -v --passphrase "$passphrase" -c --no-symkey-cache --cipher-algo "$encryption" --batch -o "${key}.tar.gz.gpg"
        else 
            tar -C / -cf - "${folders[${key}]}" | gzip -9 > "${key}.tar.gz"
        fi
    done
}

# Backup Databases Check
if [ -n "${db_username}" ]
then
    mysqldump=$(whereis mysqldump | sed 's|mysqldump: ||g')

    # Backup Databases
    declare -a databases=(
        'poo'
    );

    # Create Database Backups
    for db in ${databases[@]}
    do
        if [ -n "$log" ] && [ -z "$passphrase" ] || [ -z "$encryption" ]
        then
            log_date="$(date +%Y-%m-%d)"

            start=$(date +%s)

            $mysqldump -u $db_username -p "--password=$db_password" "$db" > "db-$db.sql"

            end=$(date +%s)

            echo "$log_date - db-$db.sql Took $(($end-$start)) seconds to extract" >> "$log"
        elif  [ -n "$log" ] && [ -n "$passphrase" ] && [ -n "$encryption" ]
        then
            log_date="$(date +%Y-%m-%d)"

            start=$(date +%s)

            $mysqldump -u $db_username -p "--password=$db_password" "$db" | gpg -v --passphrase "$passphrase" -c --no-symkey-cache --cipher-algo "$encryption" --batch -o "db-$db.sql.gpg"

            end=$(date +%s)

            echo "$log_date - db-$db.sql.gpg Took $(($end-$start)) seconds to extract and encrypt" >> "$log"
        elif  [ -z "$log" ] && [ -n "$passphrase" ] && [ -n "$encryption" ]
        then
            $mysqldump -u $db_username -p "--password=$db_password" "$db" | gpg -v --passphrase "$passphrase" -c --no-symkey-cache --cipher-algo "$encryption" --batch -o "db-$db.sql.gpg"
        else
            $mysqldump -u $db_username -p "--password=$db_password" "$db" > "db-$db.sql"
        fi
    done
fi

# Backup Local Directories Check
if [ -n "${local}" ]
then
    backup_directories

    echo -e "Backed up to Local Directory"
else 
    echo -e "Not Backed up to Local Directory"
fi

# Backup External Directories Check
if [ -n "${external}" ] && [ -n "${local}" ] 
then
    mkdir -p "${external}backup-${date}"

    cp * ${external}backup-${date}

    echo -e "Backed up to External Directory"
elif [ -n "${external}" ]
then
    backup_directories

    echo -e "Backed up to External Directory"
else 
    echo -e "Not Backed up to External Directory"
fi

# Upload Compressed Encrypted File to FTP Server Check
if [ -n "${ftp_server}" ] && [ -z "${local}" ] && [ -z "${external}" ]
then
    backup_directories

    for file in *
    do

        curl -u "$ftp_username:$ftp_password" -T ${file} "$ftp_server"
    done 

    echo -e "Backed up to FTP Server"
elif [ -n "${ftp_server}" ]
then
    curl -u "$ftp_username:$ftp_password" "$ftp_server" -Q "MKD /backup-${date}/"

    for file in *
    do
        curl -u "$ftp_username:$ftp_password" -T ${file} "$ftp_server/backup-${date}/"
    done 

    echo -e "Backed up to FTP Server"
else 
    echo -e "Not Backed up to FTP Server"
fi
