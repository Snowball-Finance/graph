export
AWS_PROFILE=snowball

init:
	terraform init
	
plan: 
	terraform plan 

apply:
	terraform apply

deploy:
	terraform init
	terraform taint -allow-missing aws_ecs_task_definition.task_definition
	terraform apply -auto-approve

destroy:
	terraform destroy
