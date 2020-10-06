$userName
$userPassword
$freePort

echo "User Name: " 
read -r userName

if id "$userName" &>/dev/null; then
    echo 'Error: User already exists'
    exit -1
fi

echo "User Password: "


# Create Linux user
sudo useradd -m $userName
sudo passwd $userName

sudo mkdir /home/$userName/www
sudo chown $userName:$userName /home/$userName/www 
sudo cp default.php /home/$userName/www/index.php
sudo chown $userName:$userName /home/$userName/www/index.php

# Create MariaDB DB
sudo mysql -p <<< "CREATE DATABASE " $userName ";"
sudo mysql -p <<< "CREATE USER " $userName " IDENTIFIED BY '" $userPassword "';"
sudo mysql -p <<< "GRANT ALL privileges ON " $userName ".* TO '" $userPassword "'@'localhost';"

# Sort usedPorts
sudo sort -t, -k2 -n usedPorts -o usedPorts

# Get first free port
lastPort=59999; # = minPort - 1

while read line; do
   port=$(echo $line | cut -d, -f2); # get 2nd column which contains port

   if [ $((port - lastPort)) -gt 1 ] ; then
        break;
   fi

   lastPort=$port
done < <(sort -t, -k2 -- usedPorts) # get lines sorted on port number

freePort=$((lastPort + 1));

echo "Using port: " $freePort

# Add newly used port to usedPorts
echo "$userName,$freePort" >> usedPorts

# Create Nginx site
cp _type $userName
sed -i -e "s/\${port}/$freePort/" -e "s/\${userName}/$userName/" $userName
sudo mv $userName /etc/nginx/sites-available/$userName
sudo ln -s /etc/nginx/sites-available/$userName /etc/nginx/sites-enabled/$userName 

sudo service nginx restart

echo "DONE"

