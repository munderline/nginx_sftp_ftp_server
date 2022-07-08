#!/bin/bash

U=${1:-sysadmin}
P=${2:-sysadmin}
sftpath="/data/sftp/${U}"
[ -e ${sftpath} ] || mkdir -p ${sftpath}

function sftp_in(){
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
    systemctl restart sshd && echo "sftp start..."
}

sftp_in
