# basic dummy ioc
cd $(TOP)

dbLoadDatabase "dbd/ioc.dbd"
ioc_registerRecordDeviceDriver(pdbbase)

dbLoadRecords $(THIS_DIR)/ioc.db

iocInit()
