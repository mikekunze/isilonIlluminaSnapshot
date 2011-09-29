#!/bin/bash

# Property of University of Wisconsin - Madison Biotechnology Center
#
# Author: Michael Kunze
# Date:   14Mar2011

source ./snapshot.bash

# Define our variables
DATE=$(date +"%m/%d/%Y:%T")
DIR="/mnt/grl/sequencers"
LOGDIR="/mnt/grl/log"
EMAIL="email@address"
EMAILSUBJECT="Sequencers Snapshot Status"

# Run sourced functions from snapshot.bash
cleanUp				# Prep Consumable data
getSequencerDirectories		# List directories to sequencer.dirs
parseDirectories		# Create sequencer.queue for non snapshot dirs

if [ -e "$LOGDIR/sendEmail.boolean" ]
    then 
        runQueue 		# Consume sequencer.queue 
        postRun                 # Email if any snapshots were made
fi
