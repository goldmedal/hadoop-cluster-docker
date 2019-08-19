#!/bin/bash

echo ""

echo -e "\nbuild docker hadoop image\n"
sudo docker build -t wasai/hadoop:1.0 .

echo ""
