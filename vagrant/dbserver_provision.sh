
yum update -y

# postgresqlサーバーインストール
yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum install -y postgresql12-server
/usr/pgsql-12/bin/postgresql-12-setup initdb
# su - postgres -c "initdb -D /var/lib/pgsql/data -E UTF8 --no-locale"
systemctl enable postgresql-12
systemctl start postgresql-12

# postgresユーザーをvagrantグループに追加。
# 運用時はvagrantユーザーがアップロードしたファイルをコピーできる様にしておく
gpasswd -a postgres vagrant
chmod 750 /home/vagrant
su - postgres -c 'cp /home/vagrant/db_setup.sh $HOME/'
su - postgres -c 'cp /home/vagrant/db.env $HOME/'

# アップロードしたファイルを削除
rm /home/vagrant/db_setup.sh
rm /home/vagrant/db.env

# データの投入はpostgresユーザーから手動で行ってください。
