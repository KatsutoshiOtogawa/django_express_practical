source /home/vagrant/appserver.env

yum update -y

# djangoのためpythonインストール
yum install python3-pip
pip3 install pipenv

# expressのためnodejsインストール
# nodejs12はltsのバージョン
curl --silent --location https://rpm.nodesource.com/setup_12.x | bash -
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
yum install -y yarn

# postgresql クライアントをインストール
# postgresql サーバーとバージョンがあっている必要がある。
yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum install -y postgresql12

# nginxサーバーインストール
yum install epel-release
yum install -y nginx
yum-config-manager --disable epel
# nginx.confのbackup作成。
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.org
cp /home/vagrant/nginx.conf /etc/nginx/nginx.conf
rm /home/vagrant/nginx.conf
systemctl enable nginx

# SELinux,firewalldの初期状態の確認
echo SELinux status is ...
getenforce
echo firewalld status is ...
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --list-all

# hostosからguestosの通信で指定のポートを開けておく。
firewall-cmd --add-service=http --zone=public --permanent
firewall-cmd --add-service=https --zone=public --permanent

# リバースプロキシの設定方法https://gobuffalo.io/en/docs/deploy/proxy
# nginxのリバースプロキシを使う場合に必要なselinuxの設定
setsebool -P httpd_can_network_connect on
setsebool -P httpd_can_network_relay on
