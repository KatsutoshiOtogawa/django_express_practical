source /home/vagrant/appserver.env

yum update -y

# djangoのためpythonインストール
yum install -y python3-pip
pip3 install pipenv

# expressのためnodejsインストール
# nodejs12はltsのバージョン
# [nexe](https://github.com/nexe/nexe)
curl --silent --location https://rpm.nodesource.com/setup_12.x | bash -
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
yum install -y yarn
yarn global add nexe


# postgresql クライアントをインストール
# postgresql サーバーとバージョンがあっている必要がある。
yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum install -y postgresql12

# yum searchするときレポジトリが404だとエラーになるので、レポジトリを無効にしておく。
yum-config-manager --disable pgdg-common
yum-config-manager --disable pgdg10
yum-config-manager --disable pgdg11
yum-config-manager --disable pgdg12
yum-config-manager --disable pgdg13
yum-config-manager --disable pgdg95
yum-config-manager --disable pgdg96

# nginxサーバーインストール
yum install -y epel-release
yum install -y nginx
yum-config-manager --disable epel
# nginx.confのbackup作成。
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.org
cp /home/vagrant/nginx.conf /etc/nginx/nginx.conf
rm /home/vagrant/nginx.conf
systemctl enable nginx
systemctl start nginx

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

# アプリケーションをサービスとして登録
# 本番字はnexeでまとめた物を実行

cat << END > /etc/systemd/system/site.service
[Unit]
Description = site provide daemon
After=syslog.target network.target

[Service]
ExecStart = /usr/bin/node /home/$APP_USER/site/app.js
WorkingDirectory=/home/$APP_USER/site
KillMode=process
Restart = always
Type = simple
User=$APP_USER
Group=$APP_GROUP

[Install]
WantedBy = multi-user.target
END


cat << END > /etc/systemd/system/input.service
[Unit]
Description = input provide daemon
After=syslog.target network.target

[Service]
ExecStart = /usr/bin/node /home/$APP_USER/input/app.js
WorkingDirectory=/home/$APP_USER/input
KillMode=process
Restart = always
Type = simple
User=$APP_USER
Group=$APP_GROUP

[Install]
WantedBy = multi-user.target
END