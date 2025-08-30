# Crafty-Backup-Export-Script
This script will use the Crafty API with the provided username and password to get all servers and copy each latest backup file to a provided folder location. Name scheme is <ServerName>_<YYYY-MM-DD>.zip

This could be useful with a cronjob to regularly copy backups to a remote location. I.E. Possibly combine with rclone mount to allow for S3 storage use or use a file share mount.

Usage:
./Export-Crafty-Backups.sh /<FolderLocation> https://<CraftyIPorDomain>:8443 admin SuperSecretPassword

Obvoiusly replace FolderLocation, CraftyIPorDomain, admin, and SuperSecretPassword with the respective values.
