all: install_requirements configure_host launch_mgmt_cluster

install_requirements:
	./01_prepare_host.sh

configure_host:
	./02_configure_host.sh

launch_mgmt_cluster:
	./03_launch_mgmt_cluster.sh

.PHONY: all install_requirements configure_host launch_mgmt_cluster
