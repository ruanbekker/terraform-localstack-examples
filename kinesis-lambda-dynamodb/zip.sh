#!/bin/bash

for function in $(ls lambda/)
do 
   pushd "lambda/$function"
   if [ -f "deployment_package.zip" ]; then rm -f deployment_package.zip; fi
   python3 -m pip install --target ./packages --requirement ./deps/requirements.txt
   pushd packages
   zip -r ../deployment_package.zip .
   popd
   pushd src/
   zip -g ../deployment_package.zip lambda_function.py
   popd
   rm -rf packages/*
   popd
done
