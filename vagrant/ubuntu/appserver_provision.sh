source /home/vagrant/appserver.env

apt update && apt upgrade -y

# djangoのためpythonインストール
apt install -y python3-pip
pip3 install pipenv

# ファイルシステムの検索を簡単にするためmlocateをインストール
apt install -y mlocate

# ポート、ネットワークの接続確認のため、インストール
apt install -y nmap

# expressのためnodejsインストール
# nodejs12はltsのバージョン
apt install -y snapd
# nodeをインストールするとnpm,yarnもインストールされる。
snap install node --channel=12/stable --classic
yarn global add nexe

# postgresql クライアントをインストール
# postgresql サーバーとバージョンがあっている必要がある。
apt install -y postgresql-client-10
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

# リバースプロキシの設定方法https://gobuffalo.io/en/docs/deploy/proxy
# Apparmorの場合は、nginxのリバースプロキシを使うための設定は不要。

# private networkの設定
echo "# private network settings." >> /etc/hosts
# appサーバーの自分のprivateアドレスを記述
echo -e "192.168.33.10\tapp\tapp" >> /etc/hosts
# dbサーバーのprivateアドレスを記述
echo -e "192.168.33.20\tdb\tdb" >> /etc/hosts

# libpg-devはプログラミング言語からpostgresqlに接続するためのライブラリ
apt install -y libpq-dev
su - vagrant -c "pip3 install psycopg2"

# postgresユーザー疎通確認
DB_HOSTNAME=db
su - vagrant -s /usr/bin/python3 << END
import psycopg2
import sys

try:
    with psycopg2.connect("host=${DB_HOSTNAME} dbname=postgres user=postgres password=postgres") as conn:
        with conn.cursor() as cur:
            cur.execute("select version();")

            # プログラミング言語経由だとcommit必要
            conn.commit()
            for row in cur.fetchall():
                print(row)
except Exception as err:
    print(err, file=sys.stderr)
END


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

# locateのデータベース更新。
updatedb
