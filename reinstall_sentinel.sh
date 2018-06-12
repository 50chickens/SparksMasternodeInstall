#!/bin/bash
SPARKS_LOC='/root/.sparkscore'

rm -r $SPARKS_LOC/sentinel > /dev/null 2>&1
echo -e "${GREEN}do quick cleanup${NC}"
rm $SPARKS_LOC/sentinel.log > /dev/null 2>&1


#apt-get -y install python-virtualenv virtualenv >/dev/null 2>&1
cd $SPARKS_LOC
git clone https://github.com/SparksReborn/sentinel.git /root/.sparkscore/sentinel >/dev/null 2>&1
cd $SPARKS_LOC/sentinel
virtualenv ./venv >/dev/null 2>&1
./venv/bin/pip install -r requirements.txt >/dev/null 2>&1


mv $SPARKS_LOC/sentinel/sentinel.conf /root/.sparkscore/sentinel/sentinel.OLD
touch $SPARKS_LOC/sentinel/sentinel.conf >/dev/null 2>&1
cat << EOF > $SPARKS_LOC/sentinel/sentinel.conf
# specify path to dash.conf or leave blank
# default is the same as DashCore
#dash_conf=/root/.sparkscore/sparks.conf
sparks_conf=/root/.sparkscore/sparks.conf

# valid options are mainnet, testnet (default=mainnet)
network=mainnet
#network=testnet

# database connection details
db_name=database/sentinel.db
db_driver=sqlite

#DrWeez

EOF
