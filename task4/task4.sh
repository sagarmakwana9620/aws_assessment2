#!/bin/sh
echo "Creating Lambdab function for starting the instance"

echo "import boto3
# Enter the region your instances are in. Include only the region without specifying Availability Zone; e.g.; 'us-east-1'
region = 'us-east-1'
# Enter your instances here: ex. ['X-XXXXXXXX', 'X-XXXXXXXX']
instances = ['i-02e3efe1eac16b80d']
def lambda_handler(event, context):
    ec2 = boto3.client('ec2', region_name=region)
    ec2.start_instances(InstanceIds=instances)
    print 'started your instances: ' + str(instances)" > lambda_function.py

zip startec2.zip lambda_function.py

aws lambda create-function --function-name pe-sm-startec2 \
--runtime python2.7 \
--role arn:aws:iam::488599217855:role/FullAccess \
--handler lambda_function.lambda_handler \
--zip-file fileb://startec2.zip \
--timeout 300 \
--region us-east-1

echo "Getting ARN for the starting ec2 lambda function"
arn1=$(aws lambda get-function-configuration --function-name pe-sm-startec2 --region us-east-1 --query '{FunctionArn:FunctionArn}' --output text)

echo "Creating Lambda for stopping the instance"

echo "import boto3
# Enter the region your instances are in. Include only the region without specifying Availability Zone; e.g., 'us-east-1'
region = 'us-east-1'
# Enter your instances here: ex. ['X-XXXXXXXX', 'X-XXXXXXXX']
instances = ['i-02e3efe1eac16b80d']
def lambda_handler(event, context):
    ec2 = boto3.client('ec2', region_name=region)
    ec2.stop_instances(InstanceIds=instances)
    print 'stopped your instances: ' + str(instances)" > lambda_function.py

zip stopec2.zip lambda_function.py

aws lambda create-function --function-name pe-sm-stopec2 \
--runtime python2.7 \
--role arn:aws:iam::488599217855:role/FullAccess \
--handler lambda_function.lambda_handler \
--zip-file fileb://stopec2.zip \
--timeout 300 \
--region us-east-1

echo "Getting ARN for the start ec2 lambda function"
arn2=$(aws lambda get-function-configuration --function-name pe-sm-stopec2 --region us-east-1 --query '{FunctionArn:FunctionArn}' --output text)
i=0
for day in {"Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"}
do
	i=$(($i+1))
	start_m=0
	start_h=9
	stop_m=0
	stop_h=17
	echo "Enter start minute time for $day or leave empty for default"
	read start_m
	echo "Enter start hour time for $day or leave empty for default"
	read start_h
	echo "Enter stop minute time for $day or leave empty for default"
	read stop_m
	echo "Enter stop hour time for $day or leave empty for default"
	read stop_h
	echo "Creating Cloudwatch Rule for starting the instance for $day"
	if [ "$start_m" = "" ];then
		start_m=0
	fi
	if [ "$stop_m" = "" ];then
		stop_m=0
	fi
	if [ "$stop_h" = "" ];then
		stop_h=17
	fi
	if [ "$start_h" = "" ];then
		start_h=9
	fi
	echo "pe-sm-startec2rule$i"
	arn3=$(aws events put-rule --name "pe-sm-startec2rule$i" --schedule-expression "cron($start_m $start_h * * ? *)" --state "ENABLED" \
	--role-arn "arn:aws:iam::488599217855:role/FullAccess" --region "us-east-1" --query "{RuleArn:RuleArn}" --output text)
	aws lambda add-permission \
	--function-name pe-sm-startec2 \
	--statement-id $i \
	--action 'lambda:InvokeFunction' \
	--principal events.amazonaws.com \
	--source-arn $arn3 \
	--region "us-east-1"

	aws events put-targets --rule "pe-sm-startec2rule$i" --targets "Id"="1","Arn"="$arn1" --region "us-east-1"

	echo "Creating Cloudwatch Rule for stopping the instance for $day"

	arn4=$(aws events put-rule --name "pe-sm-stopec2rule$i" --schedule-expression "cron($stop_m $stop_h * * ? *)" --state "ENABLED" \
	--role-arn "arn:aws:iam::488599217855:role/FullAccess" --region "us-east-1" --query "{RuleArn:RuleArn}" --output text)

	aws lambda add-permission \
	--function-name pe-sm-stopec2 \
	--statement-id $i \
	--action 'lambda:InvokeFunction' \
	--principal events.amazonaws.com \
	--source-arn $arn4 \
	--region "us-east-1"

	aws events put-targets --rule "pe-sm-stopec2rule$i" --targets "Id"="1","Arn"="$arn2" --region "us-east-1"
done