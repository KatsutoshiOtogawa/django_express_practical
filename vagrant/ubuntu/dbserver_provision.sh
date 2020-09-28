
apt update && apt upgrade -y

# DBの選択
RDBMS=postgresql
RDBMS=mysql
RDBMS=mssql
RDBMS=oracle

#
# if [$RDBMS -]
# exit 1
# fi

# ファイルシステムの検索を簡単にするためmlocateをインストール
apt install -y mlocate

# ポート、ネットワークの接続確認のため、インストール
apt install -y nmap

# postgresqlサーバーインストール
apt install -y postgresql-10
systemctl enable postgresql
systemctl start postgresql

# postgresユーザーをvagrantグループに追加することにより、vagrantフォルダの権限を追悔。
# 運用時はvagrantユーザーがアップロードしたファイルをコピーできる様にしておく
gpasswd -a postgres vagrant
chmod 750 /home/vagrant
su - postgres -c 'cp /home/vagrant/db_setup.sh $HOME/'
su - postgres -c 'cp /home/vagrant/db.env $HOME/'

# アップロードしたファイルを削除
rm /home/vagrant/db_setup.sh
rm /home/vagrant/db.env

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
apt install -y expect python3-pip
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
ufw allow 5432

# ufw設定読み込み
ufw reload

# private networkの設定
echo "# private network settings." >> /etc/hosts
# appサーバーの自分のprivateアドレスを記述
echo -e "192.168.33.10\tapp\tapp" >> /etc/hosts
# dbサーバーのprivateアドレスを記述
echo -e "192.168.33.20\tdb\tdb" >> /etc/hosts

# postgresqlサーバーが、privateネットワークからのみ接続できるように設定。
# 上の設定の方が優先度が高いので注意!
echo "# private networks connection setting" >> /etc/postgresql/10/main/pg_hba.conf
echo -e "host\tall\t\tall\t\t192.168.33.10/8\t\tmd5" >> /etc/postgresql/10/main/pg_hba.conf

# この設定を使うなら
# 本番はprivate network以外にdbserverを置かないこと。
sed -i.org "s/^#listen_addresses.*$/listen_addresses=\'*\'/" /etc/postgresql/10/main/postgresql.conf

# 設定反映
systemctl restart postgresql


# libpg-devはプログラミング言語からpostgresqlに接続するためのライブラリ
apt install -y libpq-dev
su - postgres -c "pip3 install psycopg2"

# postgresユーザー初期パスワード設定
POSTGRES_PASSWORD=postgres
su - postgres -s /usr/bin/python3 << END
import psycopg2
import sys

try:
    with psycopg2.connect("dbname=postgres user=postgres") as conn:
        with conn.cursor() as cur:
            cur.execute("ALTER USER postgres WITH PASSWORD %s",["${POSTGRES_PASSWORD}"])

             # プログラミング言語経由だとcommit必要
            conn.commit()
except Exception as err:
    print(err, file=sys.stderr)
END

# 設定トラブル時は下のコマンドで確認。
# tail /var/log/postgresql/postgresql-11-main.log
# データの投入はpostgresユーザーから手動で行ってください。


# 後処理。平時は使わないのでアンインストール。
pip3 uninstall pexpect
apt remove --purge -y expect


# locateのデータベース更新。
updatedb
