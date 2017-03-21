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
# Custom functions for MySQL consistent Azure Linux VMs backups

# Logging #####################################################################
# Functions to log messages with different levels
# in case of a critical message, the execution finishes
function log_crit {
    echo "[$(date +"${LOG_TIMESTAMP_FORMAT}")] CRIT: $@. Exiting." >> ${LOG_FILE}
    echo "$0: $@" >&2
    exit 1
}

function log_error {
    echo "[$(date +"${LOG_TIMESTAMP_FORMAT}")] ERROR: $@" >> ${LOG_FILE}
    echo "$0: $@" >&2
}

function log_info {
    echo "[$(date +"${LOG_TIMESTAMP_FORMAT}")] INFO: $@" >> ${LOG_FILE}
}

function log_warn {
    echo "[$(date +"${LOG_TIMESTAMP_FORMAT}")] WARN: $@" >> ${LOG_FILE}
}
###############################################################################

# MySQL common operations #####################################################
function mysqldump_dump_all_dbs_and_tables {

    mysqldump_cmd_infix=""
    case $role in
        "master")
            mysqldump_cmd_infix=${MYSQLDUMP_CMD_MASTER_INFIX}
        ;;
        "slave")
            mysqldump_cmd_infix=${MYSQLDUMP_CMD_SLAVE_INFIX}
        ;;
    esac

    log_info "Starting dump..."

    dump_file=""
    dump_files=""
    for database in $(${MYSQL_CMD_PREFIX} -e "SHOW DATABASES;" | egrep -v "^\s*(information_schema|mysql|performance_schema|sys)\s*$"); do
        log_info "Dumping database ${database}..."
        for table in $(${MYSQL_CMD_PREFIX} ${database} -e "SHOW TABLES;"); do
            log_info "Dumping table ${database}.${table}..."
            dump_file="${DUMPS_FOLDER}/mysqldump-${database}-${table}-$(date +"${FILE_TIMESTAMP_FORMAT}").sql.gz"
            dump_files="${dump_files} ${dump_file}"
            ${MYSQLDUMP_CMD_PREFIX} ${mysqldump_cmd_infix} ${database} ${table} | gzip > ${dump_file}
            log_info "$(du ${dump_file})"
        done
    done

   log_info "Dump finished"
}

# EVALUATE REMOVAL ############################################################
# This might be useful for some scenarios
#function mysql_optimize_table {
#    for table in $(${MYSQL_CMD_PREFIX} -e "SHOW TABLES;"); do
#        log_info "Starting optimization of table ${table}..."
#        ${MYSQL_CMD_PREFIX} -e "OPTIMIZE TABLE ${table}"
#        log_info "Table ${table} optimization finished"
#    done
#}
###############################################################################

function mysql_set_readonly {
    log_info "Setting read-only status"
    ${MYSQL_CMD_PREFIX} -e "FLUSH TABLES WITH READ LOCK; SET GLOBAL read_only = ON;"
}

function mysql_unset_readonly {
    log_info "Unsetting read-only status"
    ${MYSQL_CMD_PREFIX} -e "SET GLOBAL read_only = OFF; UNLOCK TABLES;"
}
###############################################################################

# MySQL slave operations #######################################################
function mysql_slave_start {
    if [[ $(mysql_slave_status) -ne 0 ]]; then
        log_info "Starting MySQL slave..."
        ${MYSQL_CMD_PREFIX} -e "START SLAVE;"
        sleep 1
        if [[ $(mysql_slave_status) -eq 0 ]]; then
            log_info "MySQL slave started."
        else
            log_error "MySQL slave could not be started."
        fi
    # else => MySQL slave is already started
    fi
}

function mysql_slave_status_cmd {
    ${MYSQL_SLAVE_CMD_PREFIX} -e "SHOW SLAVE STATUS \G;"
}

function mysql_slave_check_replication_delay {
    delay_seconds="$(mysql_slave_status_cmd | egrep "^\s*Seconds_Behind_Master:\s*[0-9]+" | awk '{ print $2 }')"

    # If the threshold is not defined, use a default value (60 seconds)
    if [[ "${delay_seconds}" -gt ${MYSQL_REPLICATION_DELAY_THRESHOLD:=60} ]]; then
        log_warn "There is a replication delay of ${delay_seconds} seconds, the backup might not be complete."
    fi
}

# Returns 0 if the slave is running, 1 or other number otherwise
function mysql_slave_status {
    if [[ "$(mysql_slave_status_cmd | egrep "^\s*(Slave_IO_Running|Slave_SQL_Running):\s*Yes" | wc -l)" -eq 2 ]]; then
        echo 0
    else
        echo 1
    fi
}

function mysql_slave_stop {
    if [[ $(mysql_slave_status) -eq 0 ]]; then
        mysql_slave_check_replication_delay
        log_info "Stopping MySQL slave..."
        ${MYSQL_CMD_PREFIX} -e "STOP SLAVE;"
        sleep 5
        if [[ $(mysql_slave_status) -ne 0 ]]; then
            log_info "MySQL slave stopped."
        else
            log_error "MySQL slave could not be stopped."
        fi
    # else MySQL slave is already stopped
    fi
}

###############################################################################

# MySQL service ################################################################
function mysql_svc_start {
    if [[ $(mysql_svc_status) -ne 0 ]]; then
        log_info "Starting MySQL service..."
        ${MYSQL_SVC} start &> /dev/null
        if [[ $(mysql_svc_status) -eq 0 ]]; then
            log_info "MySQL service started."
        else
            log_error "MySQL service could not be started."
        fi
    # else MySQL service is already running
    fi
}

# Returns 0 if the service is running, 1 or other number otherwise
function mysql_svc_status {
    ${MYSQL_SVC} status &> /dev/null ; echo $?
}

function mysql_svc_stop {
    if [[ $(mysql_svc_status) -eq 0 ]]; then
        log_info "Stopping MySQL service..."
        ${MYSQL_SVC} stop &> /dev/null
        if [[ $(mysql_svc_status) -ne 0 ]]; then
            log_info "MySQL service stopped."
        else
            log_error "MySQL service could not be stopped."
        fi
    # else MySQL service is already stopped
    fi
}
################################################################################
