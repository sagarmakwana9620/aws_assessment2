#!/bin/bash

echo "Enter the Public Ip of instance 1"
read ip1
echo "Enter the Public Ip of instance 2"
read ip2
echo "Provide the path to the private key to instance1"
read key1
echo "Provide the path to the private key to instance2"
read key2


key_gen="ssh-keygen -f .ssh/id_rsa -t rsa -N ''"

echo "Generating public keys in both the instances"

ssh -i $key1 ec2-user@$ip1 "${key_gen}"
ssh -i $key2 ec2-user@$ip2 "${key_gen}"

scp -i $key1 ec2-user@$ip1:.ssh/id_rsa.pub pub1.txt
scp -i $key2 ec2-user@$ip2:.ssh/id_rsa.pub pub2.txt

pub1=`cat pub1.txt`
pub2=`cat pub2.txt`

echo "Connecting the two instances"

i1="echo $pub2 >> .ssh/authorized_keys;"
i2="echo $pub1 >> .ssh/authorized_keys;"

ssh -i $key1 ec2-user@$ip1 "${i1}"
ssh -i $key2 ec2-user@$ip2 "${i2}"

echo "Now the two instances can connect passwordless"