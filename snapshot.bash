#!/bin/bash

function updateDate {
    #sleep 1 
    DATE=$(date +"%m/%d/%Y:%T")
}

function cleanUp {

    if [ -e "$LOGDIR/sendEmail.boolean" ];
	then rm $LOGDIR/sendEmail.boolean
    fi

    if [ -e "$LOGDIR/snapshot.log" ];
        then rm $LOGDIR/snapshot.log
    fi

    if [ -e "$LOGDIR/snapshot.runFolderPaths" ];
        then rm $LOGDIR/snapshot.runFolderPaths
    fi

    if [ -e "$LOGDIR/snapshot.runFolders" ];
        then rm $LOGDIR/snapshot.runFolders
    fi
}

function getSequencerDirectories {
    # Create a consumable list of sequencer directories
    find $DIR -maxdepth 3 -mindepth 2 -name Run.completed -o -name RTAComplete.txt -printf %h\\n > $LOGDIR/snapshot.dirs
}

function parseDirectories {

    cat $LOGDIR/snapshot.dirs | while read line; do

        if [ ! -e "$line/Snapshot.completed" ]
	    then
                IFS="/"

                DIRPATH=( $line )

		IFS=""
		
                echo -e ${DIRPATH[5]} >> $LOGDIR/snapshot.runFolders 
        fi
    done

    # This is where we consume the directories and determine which data already has a snapshot
    echo -e "$DATE snapshot overview:\n" > $LOGDIR/snapshot_overview.txt

    cat $LOGDIR/snapshot.dirs | while read line; do

        if [ -e "$line/Snapshot.completed" ]
            then
                read -r SNAPSHOT_DATE< $line/Snapshot.completed
                echo -e  "$line \t\t [SNAPSHOT: $SNAPSHOT_DATE]" >> $LOGDIR/snapshot_overview.txt
            else
                echo -e "$line \t\t [no snapshot]" >> $LOGDIR/snapshot_overview.txt
                echo $line >> $LOGDIR/snapshot.runFolderPaths
		touch $LOGDIR/sendEmail.boolean
        fi

    done

    echo -e "\n" >> $LOGDIR/snapshot_overview.txt
}

function runQueue {

    paste -d ', ' $LOGDIR/snapshot.runFolderPaths $LOGDIR/snapshot.runFolders > $LOGDIR/snapshot.consume

    # Begin processing required snapshots
    cat $LOGDIR/snapshot.consume | while read  line; do

	IFS=", "

	RUN=( $line )
        RUNPATH=${RUN[0]}
        RUNNAME=${RUN[1]}

        updateDate
        echo -e "$DATE Processing snapshot for $RUNNAME..." >> $LOGDIR/snapshot.log
        updateDate
        echo -e "$DATE isi snapshot create --name=$RUNNAME --path=$RUNPATH --duration=\"2 weeks\"" >> $LOGDIR/snapshot.log
        updateDate
        echo -e "$DATE echo \"$DATE\" > $RUNPATH/Snapshot.completed\n" >> $LOGDIR/snapshot.log
    done
}

function postRun {

    CAT1=$LOGDIR/snapshot_overview.txt
    echo -e "Output of snapshot.log:\n" >> $CAT1

    CAT2=$LOGDIR/snapshot.log
    cat $CAT1 $CAT2 | /bin/mail -s "$EMAILSUBJECT" "$EMAIL"
}
