# Easier triggering of the deployment

USER = ubuntu
PRIVATE_KEY = ~/.ssh/aws_rsa

deploy-test:
	ansible-playbook -c ssh -i hosts -l 'robuild-service-test' site.yaml -u "${USER}" --private-key "${PRIVATE_KEY}"

deploy:
	ansible-playbook -c ssh -i hosts -l 'robuild-service' site.yaml -u "${USER}" --private-key "${PRIVATE_KEY}"
