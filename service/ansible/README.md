# Ansible installation of the RISC OS Build service

## Install to the test system

* Update the `hosts` file to include the name of the test system
* Run the installation:
```
ansible-playbook -vvvv -c ssh -i hosts -l 'robuild-service-test' site.yaml -u ubuntu --private-key ~/.ssh/aws_rsa
```

## Install to the real back end

* Run the installation:
```
ansible-playbook -vvvv -c ssh -i hosts -l 'robuild-service' site.yaml -u ubuntu --private-key ~/.ssh/aws_rsa
```
