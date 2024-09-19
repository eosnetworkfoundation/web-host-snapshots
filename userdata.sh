USER=ubuntu

## addition ssh keys ##
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHUWNQ0UISbfmtQFdkwws25WfdOSITAVoxfXF0rD/Djv eric.passmore@eosnetwork.com - superbee.local" \
  | sudo -u "${USER}" tee -a /home/${USER}/.ssh/authorized_keys

## new user ##
USER="enf-replay"
PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPbQbXU9uyqGwpeZxjeGR3Yqw8ku5iBxaKqzZgqHhphS support@eosnetwork.com - ANY"

## does the user already exist ##
if getent passwd "${USER}" > /dev/null 2>&1; then
    echo "yes the user exists"
    exit 0
else
    echo "Creating user ${USER}"
fi

KEY_SIZE=$(echo "${PUBLIC_KEY}" | cut -d' ' -f2 | wc -c)
if [ "$KEY_SIZE" -lt 33 ]; then
    echo "Invalid public key"
    exit 1
fi

## gecos non-interactive ##
adduser "${USER}" --disabled-password --gecos ""
sudo -u "${USER}" -- sh -c "mkdir /home/enf-replay/.ssh && chmod 700 /home/enf-replay/.ssh && touch /home/enf-replay/.ssh/authorized_keys && chmod 600 /home/enf-replay/.ssh/authorized_keys"
echo "$PUBLIC_KEY" | sudo -u "${USER}" tee -a /home/enf-replay/.ssh/authorized_keys

## packages ##
apt-get update >> /dev/null
apt-get install -y git unzip jq curl nginx python3 python3-pip

## aws cli ##
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d /tmp/ >> /dev/null
/tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

## webcontent and setup script ##
sudo -i -u "${USER}" git clone https://github.com/eosnetworkfoundation/web-host-snapshots
## s3 nginx proxy ##
sudo -i -u "${USER}" git clone https://github.com/nginxinc/nginx-s3-gateway.git
## set env for s3 proxy access ##
cp /home/${USER}/web-host-snapshots/setting.env /home/${USER}/web-host-snapshots/prod.env
export "$(grep -v '^#' /home/${USER}/web-host-snapshots/prod.env | xargs)"
## remove bad checksum ##
sed 's/\s*echo "[abcdef0123456789]*\s* ${key_tmp_file}" | sha256sum --check/echo $(sha256sum ${key_tmp_file})/' /home/${USER}/nginx-s3-gateway/standalone_ubuntu_oss_install.sh > /home/${USER}/nginx-s3-gateway/standalone_ubuntu_oss_install.sh.new
mv /home/${USER}/nginx-s3-gateway/standalone_ubuntu_oss_install.sh.new /home/${USER}/nginx-s3-gateway/standalone_ubuntu_oss_install.sh
chmod 755 /home/${USER}/nginx-s3-gateway/standalone_ubuntu_oss_install.sh
/home/${USER}/nginx-s3-gateway/standalone_ubuntu_oss_install.sh
