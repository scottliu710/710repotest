#!/bin/bash
#
#
#
#
#


echo "#設定hostname#"
read -p "請輸入hostname :" hostname
hostnamectl set-hostname  --static $hostname
echo "hostnamectl set-hostname  --static $hostname"


read -p "請輸入gateway :" gateway
echo "##設定排程#"
crontab -l | { cat; echo "#校時
* * * * *  /usr/sbin/ntpdate $gateway"; } | crontab -

echo "##每月一日凌晨4:00 執行GeoIP更新#"
crontab -l | { cat; echo "#每月凌晨4:00 執行GeoIP更新
00 4 1 * *  sshpass -p 'Sapphire%47' scp -P22 root@10.21.1.243:/usr/local/nginx/conf/GeoLite2-ASN.mmdb /usr/local/nginx/conf/
00 4 1 * *  sshpass -p 'Sapphire%47' scp -P22 root@10.21.1.243:/usr/local/nginx/conf/GeoLite2-City.mmdb /usr/local/nginx/conf/
00 4 1 * *  sshpass -p 'Sapphire%47' scp -P22 root@10.21.1.243:/usr/local/nginx/conf/GeoLite2-Country.mmdb /usr/local/nginx/conf/"; } | crontab -


cd /root
rpm -ivh metricbeat-7.4.0-x86_64.rpm
rpm -ivh filebeat-7.4.0-x86_64.rpm

read -p "請輸入要抓metribeat跟filebeat的ELK IP :" elkip
sed -i "s/localhost:9200/$elkip:9200/g" /etc/metricbeat/metricbeat.yml
sed -i 's/#username: "elastic"/username: "elastic"/g' /etc/metricbeat/metricbeat.yml
sed -i 's/#password: "changeme"/password: "Gogo!elk"/g' /etc/metricbeat/metricbeat.yml

sed -i '/#hosts/c\  hosts: ["localhost:5044"];' /etc/filebeat/filebeat.yml
sed -i "s/localhost:5044/$elkip:5044/g" /etc/filebeat/filebeat.yml

systemctl start filebeat
systemctl start metricbeat


echo "SELINUX=disabled!!!"
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

echo "#安裝校時#"
yum install -y ntp


echo "#安裝vim#"
yum install vim -y

echo "#安裝SNMP#"
yum -y install net-snmp net-snmp-libs net-snmp-utils net-snmp-devel net-snmp-perl vim update ntp
yum -y install open-vm-tools epel-release tcping wget


cat <<EOF > /etc/firewalld/services/snmp.xml
<?xml version="1.0" encoding="utf-8"?>
	<service>
	  <short>SNMP</short>
	  <description>SNMP protocol</description>
	  <port protocol="udp" port="161"/>
	</service>
EOF

mv /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.bak

cat <<EOF > /etc/snmp/snmpd.conf
com2sec notConfigUser default public
group   notConfigGroup v1           notConfigUser
group   notConfigGroup v2c           notConfigUser
access notConfigGroup "" any noauth exact all none none
view all included .1 80
EOF

systemctl restart snmpd 
systemctl enable snmpd
 
systemctl restart firewalld
firewall-cmd --zone=public --add-port=161/udp --permanent
firewall-cmd --reload
systemctl status firewalld
firewall-cmd --list-all

sed -i "s/#UseDNS yes/UseDNS no/"  /etc/ssh/sshd_config




echo "/etc/sysctl.conf configuring!!!"
echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_recycle = 1" >>/etc/sysctl.conf
echo "net.ipv4.tcp_fin_timeout = 3" >> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 20000 65000" >>/etc/sysctl.conf


echo "### Defending SYN Flood Attack" >> /etc/sysctl.conf
echo "#net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf

echo "### Increasing the SYN backlog queue" >> /etc/sysctl.conf
echo "#net.ipv4.tcp_max_syn_backlog = 2048" >> /etc/sysctl.conf

echo "### Reducing SYN_ACK retries" >> /etc/sysctl.conf
echo "#net.ipv4.tcp_synack_retries = 3" >> /etc/sysctl.conf

echo "### Setting SYN_RECV timeout [ not found file or path ]" >> /etc/sysctl.conf
echo "#net.ipv4.netfilter.ip_conntrack_tcp_timeout_syn_recv=45" >> /etc/sysctl.conf

echo "### Preventing IP spoofing" >> /etc/sysctl.conf
echo "#net.ipv4.conf.all.rp_filter = 1" >> /etc/sysctl.conf

echo "#disable ipv6" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf

echo "/etc/sysctl.conf configured!!!"

echo "Installing  package"
yum -y install gcc gcc-c++ make libtool zlib zlib-devel openssl openssl-devel
yum -y install geoip geoip-devel
yum -y install pcre pcre-devel
yum -y install net-snmp* ntp* wget
yum -y groupinstall 'Development Tools'


echo "firewall port 80 open done"
firewall-cmd --add-port=80/tcp --permanent
echo "firewall port 443 open done"
firewall-cmd --add-port=443/tcp --permanent
echo "firewall reload"
firewall-cmd --reload

yum -y install epel-release


echo "#複製ngx_http_geoip2_module#"
tar -zxvf 3.2.tar.gz
cp -r ngx_http_geoip2_module-3.2 /usr/local/src

echo "#複製nginx-goodies-nginx-sticky-module-ng-08a395c66e42#"
tar -zxvf master.tar.gz
mkdir /root/soft
cp -r nginx-goodies-nginx-sticky-module-ng-08a395c66e42/ /root/soft/

echo "#複製nginx-1.20.2#"
tar -zxvf nginx-1.20.2.tar.gz
cp -r  nginx-1.20.2/ /usr/local/


echo "#指定/ tmp目錄下載套件#"
cd /tmp
yum -y install gcc gcc-c++ make libtool zlib zlib-devel openssl openssl-devel
yum -y install geoip geoip-devel
yum -y install pcre pcre-devel
yum -y install net-snmp * ntp * wget
yum groupinstall 'Development Tools'


echo "#編譯libmaxminddb#"
cd /usr/local/src
git clone --recursive https://github.com/maxmind/libmaxminddb
cd libmaxminddb
./bootstrap
./configure
make && make install
ldconfig
mmdblookup --version

cd /usr/local/nginx-1.20.2

echo "＃開始編譯安裝nginx套件#"
./configure --prefix=/usr/local/nginx --with-http_realip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_stub_status_module --without-select_module --without-poll_module --with-http_geoip_module --with-ipv6 --with-http_ssl_module --with-openssl-opt=enable-tlsext --add-module=/root/soft/nginx-goodies-nginx-sticky-module-ng-08a395c66e42 --add-dynamic-module=/usr/local/src/ngx_http_geoip2_module-3.2
make && make install

 
echo "#啟動nginx#"
/usr/local/nginx/sbin/nginx


echo "#設定開機時啟用#"
chmod a+x /etc/rc.local
echo "#auto start nginx service" >> /etc/rc.local
echo "./usr/local/nginx/sbin/nginx" >> /etc/rc.local
ldconfig


echo "#複製conf到/usr/local/nginx/conf#"
cd /root
tar -zxvf conf.tar.gz
\cp -r conf/* /usr/local/nginx/conf/



echo "#更改limits.conf#"

echo "* - nofile 655360" >> /etc/security/limits.conf
echo "* soft nofile 655360" >> /etc/security/limits.conf
echo "* hard nofile 655360" >> /etc/security/limits.conf
echo "* soft nproc 30000" >> /etc/security/limits.conf
echo "* hard nproc 30000" >> /etc/security/limits.conf


sudo sh -c "echo /usr/local/lib  >> /etc/ld.so.conf.d/local.conf"
ldconfig

echo "#檢查nginx#"
/usr/local/nginx/sbin/nginx -t
ln -sf /usr/local/nginx/sbin/nginx /usr/local/sbin/nginx



echo "更新到最新版!!!"
yum -y update

echo "請手動重啟!!!"
echo "reboot now"




