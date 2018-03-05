#!/bin/bash

STACK_NAME="VPCs"
STACK_BUCKET_PATH="cf.awsguy.solutions/cf-vpcs"
MASTER_STACK_FILE_NAME="master.yaml"
TAGS="Key=auto-delete,Value=no"
PARAMETERS=""

# loop through the yaml files, validating each template
for i in *.yaml; do
    [ -f "$i" ] || break
    printf "Validating CloudFormation Template $i..."
    RESULT=$(aws cloudformation validate-template --template-body file://$i 2>&1)
    if [ $? != 0 ]; then
      echo "Error"
      echo ""
      echo $RESULT
      echo ""
      exit
    else
      echo "Good"
    fi
done

# upload all CloudFormation template files to s3
for i in *.yaml; do
    [ -f "$i" ] || break
    printf "Syncing CloudFormation Template $i..."
    RESULT=$(aws s3 cp $i s3://$STACK_BUCKET_PATH/$i)
    if [ $? != 0 ]; then
      echo "Error"
      echo ""
      echo $RESULT
      echo ""
      exit
    else
      echo "Complete"
    fi
done

# check to see if the stack exists so if we need to create or update
echo "Checking if $STACK_NAME stack exists"
RESULT=$(aws cloudformation describe-stacks --stack-name $STACK_NAME 2>&1)
CF_CMD=""
if [ $? = 0 ]; then
    echo "Stack exists, performing an update..."
    CF_CMD="update-stack"
else
    echo "Stack doesn't exist, creating..."
    CF_CMD="create-stack"
fi

# create or update the stack
aws cloudformation $CF_CMD \
    --stack-name $STACK_NAME \
    --template-url https://s3.amazonaws.com/$STACK_BUCKET_PATH/$MASTER_STACK_FILE_NAME \
    --tags $TAGS \
    --parameters $PARAMETERS \
    --capabilities CAPABILITY_IAM
