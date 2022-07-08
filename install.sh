#!/bin/env bash

U=${1:-sysadmin}
P=${2:-sysadmin}
sftpath="/data/sftp/${U}"
[ -e ${sftpath} ] || mkdir -p ${sftpath}

function sftp_in(){
    echo "sftp install..."
    # user group and pass
    groupadd sftp
    useradd -g sftp -s /bin/false ${U}
    echo "${U}:${P}" | chpasswd
    usermod -d ${sftpath} ${U}
    # sshd_config
    context=("Match Group sftp" "ChrootDirectory ${sftpath}" "ForceCommand    internal-sftp" "AllowTcpForwarding no" "X11Forwarding no")
    for line in "${context[@]}"
    do
      # echo ${line}
      grep "^${line}" /etc/ssh/sshd_config || echo ${line} >> /etc/ssh/sshd_config
      sleep 1
    done
    # chroot
    chown root:sftp ${sftpath} && chmod 755 ${sftpath}
    # upload
    sftpath_upload="${sftpath}/upload"
    [ -e ${sftpath_upload} ] || mkdir -p ${sftpath_upload}
    chown ${U}:sftp ${sftpath_upload}
    chmod 755 ${sftpath_upload}
    # start...
    systemctl restart sshd && echo -e "\033[5;32m===============sftp start=================\033[0m"
}

function ftp_in(){
    echo "ftpd install..."
    yum install -y pam pam-devel vsftpd
    mkdir -p /var/ftp/virtual
    useradd vsftpd -M -s /sbin/nologin
    useradd ftpvload -d /var/ftp/ -s /sbin/nologin
    sleep 3
    chown -R ftpvload.ftpvload /var/ftp/
    sleep 5

    mv /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.back
    echo "anonymous_enable=NO
    local_enable=YES
    write_enable=YES
    local_umask=022
    anon_upload_enable=NO
    anon_mkdir_write_enable=NO
    dirmessage_enable=YES
    xferlog_enable=YES
    connect_from_port_20=YES
    chown_uploads=NO
    xferlog_file=/var/log/vsftpd.log
    xferlog_std_format=YES
    async_abor_enable=YES
    ascii_upload_enable=YES
    ascii_download_enable=YES
    ftpd_banner=Welcome to FTP Server
    chroot_local_user=YES
    ls_recurse_enable=NO
    listen=YES
    hide_ids=YES
    pam_service_name=vsftpd
    userlist_enable=YES
    guest_enable=YES
    guest_username=ftpvload
    virtual_use_local_privs=YES
    user_config_dir=/etc/vsftpd/vconf" > /etc/vsftpd/vsftpd.conf

    cp /etc/pam.d/vsftpd /etc/pam.d/vsftpd.backup
    sed -i s/^/#/g /etc/pam.d/vsftpd
    echo "auth    sufficient      /lib64/security/pam_userdb.so    db=/etc/vsftpd/virtusers
    account sufficient      /lib64/security/pam_userdb.so    db=/etc/vsftpd/virtusers" >> /etc/pam.d/vsftpd
    sleep 3

    touch /var/log/vsftpd.log
    chown vsftpd.vsftpd /var/log/vsftpd.log
    mkdir /etc/vsftpd/vconf/ -p
    sleep 3

    echo -e ${U}"\n"${P} > /etc/vsftpd/virtusers
    db_load -T -t hash -f /etc/vsftpd/virtusers /etc/vsftpd/virtusers.db
    mkdir -p /var/ftp/virtual/${U} && chmod 777 -R /var/ftp/virtual/${U}

    echo "local_root=/var/ftp/virtual/${U}
    allow_writeable_chroot=YES
    anonymous_enable=NO
    write_enable=YES
    local_umask=022
    anon_upload_enable=NO
    anon_mkdir_write_enable=NO
    idle_session_timeout=600
    data_connection_timeout=120
    max_clients=10
    max_per_ip=5" > /etc/vsftpd/vconf/${U}

    systemctl restart vsftpd && echo -e "\033[5;32m===============ftp start=================\033[0m"
}

function nginx_in(){
    # require install nginx
    # exmple centos
    echo "nginx install..."
    yum install nginx wget -y || apt install -y nginx
    sed -i 's/80/18888/g' /etc/nginx/nginx.conf
    file_path="/data/www/download/"
    [ -d ${file_path} ] || mkdir -p ${file_path}
    file_server="/usr/local/bin/file_server"
    pkill file_server  
    wget -O ${file_server} -c https://github.com/munderline/nginx_sftp_ftp_server/raw/main/server && chmod +x ${file_server}
    wget -O /etc/nginx/conf.d/down_up.conf -c https://raw.githubusercontent.com/munderline/nginx_sftp_ftp_server/main/down_up.conf
    /usr/bin/setsid ${file_server} >/dev/null 2>&1 &
    nginx -s reload > /dev/null 2>&1 || nginx
    echo -e "\033[5;32m===============nginx start=================\033[0m"
}

setenforce 0
nginx_in 
ftp_in
sftp_in
echo -e "\033[5;32m===============username&password-->${U}:${P}=================\033[0m"
