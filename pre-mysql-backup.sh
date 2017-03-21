#!/bin/bash
#
# (C) 2017, CAPSiDE SL. All rights reserved. https://www.capside.com
# Author javier.martin@capside.com
# License Apache 2.0 http://www.apache.org/licenses/LICENSE-2.0
#
# This piece of software was written and published for testing purposes;
# you are solely responsible for determining the appropriateness of
# using or redistributing it and you assume any risks associated.
#
# PRE wrapper script for MySQL consistent Azure Linux VMs backups

# Executes the main to start PRE actions

/bin/bash /opt/capside/azure/mysql-app-consistent-backup.sh pre
