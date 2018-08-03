import json
def get_arn():
	with open('data.json') as f:
		arn=json.load(f)
	return arn['FunctionArn']

get_arn()