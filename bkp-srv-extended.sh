#!/bin/bash

# Dependencies
source helpers.sh

# Global vars

SUCCEED=0
FAILED=0

DATE_DAILY=`date +"%Y-%m-%d"`
MONTH_DAY=`date +"%d"`
WEEK_DAY=`date +"%u"`

# Subfunctions

generate_backup_files () {
	SITENAME=$(basename $2)
	DBFILE=$INCOMING_FOLDER/$3.sql
	TAR_NAME=$SITENAME"_"$DATE_DAILY".tar.gz"

	# If the site has a database
	if [ $# -eq 4 ]; then
		# Dump MySQL database
		e_arrow "Dumping database "$3
		mysqldump -h 127.0.0.1 -u $4 -p$5 $3 > $DBFILE 2>&1

		# Compress databases and files
		e_arrow "Generating tarball for "$SITENAME
		tar -czf $INCOMING_FOLDER/$TAR_NAME --exclude-vcs $DBFILE $2 2>&1

		# Rm DB dump
		rm $DBFILE;
	else
		# Compress files
		e_arrow "Generating tarball for "$SITENAME
		tar -czf $INCOMING_FOLDER/$TAR_NAME --exclude-vcs $2 2>&1
	fi;

	# Check if tarball has been generated. Notify if failed.
	if [ ! -f $INCOMING_FOLDER/$TAR_NAME ]; then
		notify "Failed $SITENAME" "The backup of $SITENAME failed, please check it out"
		echo "";
		return 1;
	fi

	# On the first day of the month
	if [[ "$1" == "daily" ]] ; then
		DEST_FOLDER=$BACKUP_FOLDER_DAILY"/"$DATE_DAILY
	elif [[ "$1" == "weekly" ]]; then
		DEST_FOLDER=$BACKUP_FOLDER_WEEKLY"/"$DATE_DAILY
	elif [[ "$1" == "monthly" ]]; then
		DEST_FOLDER=$BACKUP_FOLDER_MONTHLY"/"$DATE_DAILY
	fi

	# if the folder doesnt exist yet
	if [ ! -d "$DEST_FOLDER" ]; then
		mkdir $DEST_FOLDER
	fi

	# Move the backup to the correct folder
	e_arrow "Moving file for "$SITENAME
	mv -v $INCOMING_FOLDER/$TAR_NAME $DEST_FOLDER

}

clean_local_backup () {
	# daily - keep for 14 days
	find $BACKUP_FOLDER"/backup.daily/" -maxdepth 1 -mtime +14 -type d -exec rm -rv {} \;

	# weekly - keep for 60 days
	find $BACKUP_FOLDER"/backup.weekly/" -maxdepth 1 -mtime +60 -type d -exec rm -rv {} \;

	# monthly - keep for 300 days
	find $BACKUP_FOLDER"/backup.monthly/" -maxdepth 1 -mtime +300 -type d -exec rm -rv {} \;
}

#copy_backup_to_ftp () {
#
#}

#clean_ftp_backup () {
#
#}

# Main Function

backup () {

	if [[ "$1" == "daily" ]]; then
		e_header $(basename $2);
	elif [[ "$1" == "weekly" && "$WEEK_DAY" -eq 5 ]]; then
		e_header $(basename $2);
	elif [[ "$1" == "monthly" && "$MONTH_DAY" -eq 1 ]]; then
		e_header $(basename $2);
	else
		e_note "No backup required for "$(basename $2)
		return 0;
	fi;

	if generate_backup_files $1 $2 $3 $4 $5; then
		SUCCEED=$[SUCCEED + 1];
		e_success "Success"
	else
		FAILED=$[FAILED + 1];
		e_error "FAILED"
	fi;
}
