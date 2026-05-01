= Installation notes for AWS machine.

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt-get install docker-ce docker-ce-cli containerd.io

sudo usermod -aG docker ubuntu

sudo apt-get install python3-pip python3-virtualenv

python3 -m pip install -r source/requirements.txt



sudo apt-add-repository ppa:fish-shell/release-3
sudo apt-get update
sudo apt-get install fish
