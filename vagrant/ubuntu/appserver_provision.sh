source /home/vagrant/appserver.env

apt update && apt upgrade -y

# djangoのためpythonインストール
apt install -y python3-pip
pip3 install pipenv

# expressのためnodejsインストール
# nodejs12はltsのバージョン
apt install -y snapd
# nodeをインストールするとnpm,yarnもインストールされる。
snap install node --channel=12/stable --classic
yarn global add nexe

# postgresql クライアントをインストール
# postgresql サーバーとバージョンがあっている必要がある。
apt install -y postgresql-client-common

# nginxサーバーインストール
apt install -y nginx
# nginx.confのbackup作成。
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.org
cp /home/vagrant/nginx.conf /etc/nginx/nginx.conf
rm /home/vagrant/nginx.conf
systemctl enable nginx
systemctl start nginx

# sites-enabled/defaultの説明通り削除
rm /etc/nginx/sites-enabled/default

# AppArmor,firewalldの初期状態の確認
echo AppArmor status is ...
aa-status
aa-enabled
echo ufw status is ...
systemctl enable ufw
systemctl start ufw
# ufw 有効化のためインストール
# expectは内部処理に癖があるため、pexpectを使う。
apt install -y expect
pip3 install pexpect
python3 << END
import pexpect

prc = pexpect.spawn("ufw enable")
prc.expect("Command may disrupt existing ssh connections. Proceed with operation")
prc.sendline("y")
prc.expect( pexpect.EOF )
END
ufw status verbose

# ファイアウォールの設定
# hostosからguestosの通信で指定のポートを開けておく。
ufw allow 22
ufw allow 80
ufw allow 443
ufw allow 3000

# ufw設定読み込み
ufw reload

# リバースプロキシの設定方法https://gobuffalo.io/en/docs/deploy/proxy
# nginxのリバースプロキシを使う場合に必要なselinuxの設定
# setsebool -P httpd_can_network_connect on
# setsebool -P httpd_can_network_relay on

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