# nginx_file_server
# 使用nginx搭建文件上传和下载服务器
1. 下载路由: http://ip/download
2. 上传路由: http://ip/upload
3. 上传文件默认路径: /data/www/download
# 快速安装ftp&sftp&nginx,后面参数换成自己的用户名和密码
curl -L https://raw.githubusercontent.com/munderline/nginx_sftp_ftp_server/main/install.sh | sh -s -- username passwd
