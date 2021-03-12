#!/bin/bash

export AWS_PAGER=""

set -x -e

for i in {1..2}
do

original_message=$(aws sqs receive-message --queue-url $SQS_URL | jq .Messages[0])

echo $original_message

echo

receipt_handle=$(jq '.ReceiptHandle' <<< $original_message)

echo receipt_handle : $receipt_handle

echo

message=$(jq -r '.Body | fromjson' <<< $original_message)


echo $message

echo

subject=$(echo $message | jq -r '.Records[0].Sns.Subject')
echo $subject

echo

args=$(echo $message | jq -r '.Records[0].Sns.Message')
echo $args

echo

echo "Some::Class.foo("\'$subject\', $args")" >> dlq-messages.txt

aws sqs delete-message --queue-url $SQS_URL \
                       --receipt-handle ${receipt_handle//\"/}
                       >> dlq-deleted-output.prod.txt

done
