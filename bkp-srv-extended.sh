#!/bin/bash

# Dependencies
source helpers.sh

# Global vars

SUCCEED=0
FAILED=0

# Subfunctions

generate_backup_files () {
	SITENAME=$(basename $1)
	e_header $SITENAME;

	DBFILE=$INCOMING_FOLDER/$2.sql
	DATE_DAILY=`date +"%Y-%m-%d"`
	MONTH_DAY=`date +"%d"`
	WEEK_DAY=`date +"%u"`

	TAR_NAME=$SITENAME"_"$DATE_DAILY".tar.gz"

	# Dump MySQL database
	e_arrow "Dumping database "$2
	mysqldump -h 127.0.0.1 -u $3 -p$4 $2 > $DBFILE 2>&1

	# Compress databases and files
	e_arrow "Generating tarball for "$SITENAME
	tar -czf $INCOMING_FOLDER/$TAR_NAME $DBFILE $1 2>&1

	# Rm temp file
	rm $DBFILE;

	# Check if tarball has been generated. Notify if failed.
	if [ ! -f $INCOMING_FOLDER/$TAR_NAME ]; then
		notify "Failed $SITENAME" "The backup of $SITENAME failed, please check it out"
		echo "";
		return 1;
	fi

	# On the first day of the month
	if [ "$MONTH_DAY" -eq 1 ] ; then
		DEST_FOLDER=$BACKUP_FOLDER"/backup.monthly/"$DATE_DAILY
	else
		# On fridays
		if [ "$WEEK_DAY" -eq 5 ] ; then
			DEST_FOLDER=$BACKUP_FOLDER"/backup.weekly/"$DATE_DAILY
		# Any other day
		else
			DEST_FOLDER=$BACKUP_FOLDER"/backup.daily/"$DATE_DAILY
		fi
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
	if generate_backup_files $1 $2 $3 $4; then
		SUCCEED=$[SUCCEED + 1];
		e_success "Success"
	else
		FAILED=$[FAILED + 1];
		e_error "FAILED"
	fi;
}
