# Getting Started

The following scripts:

 * mysql-app-consistent-backup.sh
 * mysql-app-consistent-backup-env.sh
 * mysql-app-consistent-backup-funcs.sh
 * post-mysql-backup.sh
 * pre-mysql-backup.sh

are part of the result of a collaboration between Microsoft and CAPSiDE to test a preview feature of application consistent backups for Linux virtual machines in Azure.

The scripts _pre-mysql-backup.sh_ and _post-mysql-backup.sh_ are wrappers for the actions to be executed before and after the VM snapshot actually takes place. The main script _mysql-app-consistent-backup.sh_ makes use of the variables and functions defined in _mysql-app-consistent-backup-env.sh_ and _mysql-app-consistent-backup-funcs.sh_. Each one of them include a short description in the header.

The goal was to define a very simple and standard use case for a MySQL master-slave replication scenario assuming minimal replication delay and where the slaves are used as the source for the backups.

Please, note that these scripts were written and published for testing purposes; you are solely responsible for determining the appropriateness of using or redistributing them and you assume any risks associated.

You can find more information in the official announcement and the related blog posts.
