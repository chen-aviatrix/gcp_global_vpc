#!/bin/bash
echo ">> Updating apt..."
sudo apt update

echo ">> Installing iperf2..."
sudo apt-get -y install iperf

echo ">> Installing iperf3..."
sudo apt-get -y install iperf3

echo ">> Installing tcpdump..."
sudo apt-get -y install tcpdump

echo ">> Installing ipset..."
sudo apt-get -y install ipset

echo ">> Installing iproute2..."
sudo apt-get -y install iproute2

echo ">> Installing lighttpd (web server)..."
sudo apt-get -y install lighttpd

echo ">> Installing vsftpd (FTP server)..."
sudo apt-get -y install vsftpd

echo ">> Installing curl..."
sudo apt-get -y install curl
