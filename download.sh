sudo tftp 192.168.0.251 -m binary -c get default.sh default.sh
sudo chmod +x default.sh
./default.sh
sudo rm default.sh
sudo rm flow*
