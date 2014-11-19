#!/bin/sh

cd $HOME

if [ -f bootstrapping-done ]; then
	exit 0
fi

if [ $# -ne 8 ]; then
	echo "Usage: $0 user group replication-master replication-port replication-user replication-password datadir confdir" 1>&2
	exit 64
fi

USER=$1
GROUP=$2
REPL_MASTER=$3
REPL_PORT=$4
REPL_USER=$5
REPL_PASS=$6
DATA_DIR=$7
CONF_DIR=$8

DATA_DIR_BAK=${DATA_DIR}.BAK

echo "*:*:*:${REPL_USER}:${REPL_PASS}" > .pgpass
chmod 0600 .pgpass

master_reachable=0

# wait 12 * 5 seconds = 60 seconds
for i in `seq 12`; do
	psql --host ${REPL_MASTER} --port ${REPL_PORT} --username ${REPL_USER} --dbname postgres --no-password --command "SELECT 1"

	if [ $? -eq 0 ]; then
		master_reachable=1
		break
	fi

	sleep 5
done

if [ ${master_reachable} -eq 0 ]; then
	echo "${REPL_MASTER}:${REPL_PORT} not reachable" 1>&2
	rm -f .pgpass
	exit 1
fi

mv ${DATA_DIR} ${DATA_DIR_BAK} && mkdir ${DATA_DIR} && chown ${USER}:${GROUP} ${DATA_DIR} && chmod 0700 ${DATA_DIR} && chcon --reference=${DATA_DIR_BAK} ${DATA_DIR}
/usr/bin/pg_basebackup -h ${REPL_MASTER} -D ${DATA_DIR} -U ${REPL_USER} --no-password --xlog
rm -f .pgpass

if [ "${CONF_DIR}" = "${DATA_DIR}" ]; then
	cp -a ${DATA_DIR_BAK}/postgresql.conf ${DATA_DIR}
	cp -a ${DATA_DIR_BAK}/recovery.conf ${DATA_DIR}
fi
if [ -f "${DATA_DIR_BAK}/server.crt" ]; then
	cp -a ${DATA_DIR_BAK}/server.crt ${DATA_DIR}
fi
if [ -f "${DATA_DIR_BAK}/server.key" ]; then
	cp -a ${DATA_DIR_BAK}/server.key ${DATA_DIR}
fi

rm -f ${DATA_DIR}/pg_log/*
rm -rf ${DATA_DIR_BAK}

date > bootstrapping-done
