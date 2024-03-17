# BASH Backup Script
This bash script automates the backup process for multiple directories and MySQL databases to both a local location and FTP server. Its designed to simplyify the procedure, ensuring data and security.

### Features: 
>Multiple Directory Backup: Backs up specified directories to a designated local location.

>MySQL Database Backup: Performs backups of MySQL databases and stores them locally.

>FTP Server Backup: Transfers backups to a remote FTP server for offsite storage and redundancy.

>Customizable Configuration: Easily configure backup directories, MySQL credentials, local backup location, and FTP server details.

### Usage: 
1. Clone the repo or download the script.
2. Configure the script by editing the varables to specify backup directories, MySQL credentials, local backup location, and FTP server details.
3. Run the script manually or set up a cron job for automated backups.

### Dependencies:
> BASH SHELL
> MySQL client for database backups.
> FTP client for transferring backups to a remote server.

### Example: 
./backup.sh

### Disclaimer:
>Ensure sensitive information like MySQL passwords and FTP credentials are stored securely and not exposed in the script itself.

>Test the script in a contained environment before using in production.

Get in touch if you encounter any issues or bugs!
