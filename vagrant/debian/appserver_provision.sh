source /home/vagrant/appserver.env

# grub-pcでboot loaderを最新の物にする必要はないので、
# パッケージが更新されないようにしておく。
apt-mark hold grub-pc
apt update && apt upgrade -y

# djangoのためpythonインストール
apt install -y python3-pip
pip3 install pipenv

# expressのためnodejsインストール
# nodejs12はltsのバージョン
apt install -y snapd
# nodeをインストールするとnpm,yarnもインストールされる。
snap install node --channel=12/stable --classic
# ubuntu以外はsnapにパスが通っていないので通す。
echo export PATH=$PATH:/snap/bin >> $HOME/.bashrc
source $HOME/.bashrc
su - vagrant -c 'echo export PATH=$PATH:/snap/bin >> $HOME/.bashrc'
yarn global add nexe

# postgresql クライアントをインストール
# postgresql サーバーとバージョンがあっている必要がある。
apt install -y postgresql-client-common

# nginxサーバーインストール
apt install -y nginx
# sites-available/defaultのbackup作成。
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.org
cp /home/vagrant/default /etc/nginx/sites-available/default
rm /home/vagrant/default

# nginx有効化
systemctl enable nginx
systemctl start nginx


# AppArmor,firewalldの初期状態の確認
echo AppArmor status is ...
aa-status
aa-enabled
echo ufw status is ...
# debianではデフォルトでiptablesなのでufwに変える。
apt install -y ufw
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
# 後処理。平時は使わないのでアンインストール。
pip3 uninstall pexpect
apt remove --purge -y expect

# ファイアウォールの設定
# hostosからguestosの通信で指定のポートを開けておく。
ufw allow 22
ufw allow 80
ufw allow 443
ufw allow 3000

# ufw設定読み込み
ufw reload

# # リバースプロキシの設定方法https://gobuffalo.io/en/docs/deploy/proxy
# # nginxのリバースプロキシを使う場合に必要なselinuxの設定
# setsebool -P httpd_can_network_connect on
# setsebool -P httpd_can_network_relay on

# # アプリケーションをサービスとして登録
# # 本番字はnexeでまとめた物を実行

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