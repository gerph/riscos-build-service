= Installation notes for AWS machine.

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt-get install docker-ce docker-ce-cli containerd.io

sudo usermod -aG docker ubuntu

sudo apt-get install python-pip moreutils
#sudo update-alternatives --install /usr/bin/python python /usr/bin/python2.7 2

sudo pip install Flask==1.1.1 websocket-server==0.4



sudo apt-add-repository ppa:fish-shell/release-3
sudo apt-get update
sudo apt-get install fish
