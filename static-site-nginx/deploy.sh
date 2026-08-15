#!/bin/bash

echo "Comenzando deploy"

rsync -av "$1/" server-ubuntu:/var/www/html/
