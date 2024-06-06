#!/bin/bash

# Hàm cài đặt Mosquitto
install_mosquitto() {
    sudo apt update
    sudo apt install -y mosquitto mosquitto-clients
    sudo systemctl enable mosquitto
    sudo systemctl start mosquitto
    sudo iptables -A INPUT -p tcp --dport 8883 -j ACCEPT
    sudo iptables-save
}

# Hàm cấu hình Mosquitto với Let's Encrypt SSL
configure_mosquitto_letsencrypt() {
    DOMAIN=$1

    # Cài đặt Certbot
    #sudo apt update -y
    sudo apt install -y certbot #python3-certbot-nginx
    read -p "Enter your email (for Let's Encrypt): " EMAIL
    echo "----------------------------------------------------------"
    # Lấy chứng chỉ SSL từ Let's Encrypt
    #sudo certbot certonly --nginx -d $DOMAIN
    sudo certbot certonly --standalone --preferred-challenges http -d "$DOMAIN" --email "$EMAIL" --agree-tos --non-interactive
    
    # Sao chép các thông tin cert để fix lỗi phân quyền giữa cert-bot và mosquitto
    sudo mkdir -p /etc/mosquitto/certs
    sudo cat /etc/letsencrypt/live/$DOMAIN/cert.pem > /etc/mosquitto/certs/certificate.pem
    sudo cat /etc/letsencrypt/live/$DOMAIN/fullchain.pem > /etc/mosquitto/certs/ca.pem
    sudo cat /etc/letsencrypt/live/$DOMAIN/privkey.pem > /etc/mosquitto/certs/private.key
    sudo chmod 0600 /etc/mosquitto/certs/*
    sudo chown mosquitto: /etc/mosquitto/certs/*
    
    # Cấu hình Mosquitto với chứng chỉ SSL từ Let's Encrypt

    sudo tee /etc/mosquitto/conf.d/ssl.conf > /dev/null <<EOT
listener 8883
cafile /etc/mosquitto/certs/ca.pem
certfile /etc/mosquitto/certs/certificate.pem
keyfile /etc/mosquitto/certs/private.key
require_certificate true
EOT

    sudo systemctl restart mosquitto
    #tạo service tự động gia hạn cert-bot
    cat << 'EOF' > /usr/local/bin/update_mosquitto_certs.sh
#!/bin/bash
sleep 10
sudo cat /etc/letsencrypt/live/$DOMAIN/cert.pem > /etc/mosquitto/certs/certificate.pem
sudo cat /etc/letsencrypt/live/$DOMAIN/fullchain.pem > /etc/mosquitto/certs/ca.pem
sudo cat /etc/letsencrypt/live/$DOMAIN/privkey.pem > /etc/mosquitto/certs/private.key
sudo chmod 0600 /etc/mosquitto/certs/*
sudo chown mosquitto: /etc/mosquitto/certs/*
# Gửi tín hiệu HUP để Mosquitto nạp lại cấu hình
sudo pkill -HUP -x mosquitto
EOF

    # Cấp quyền thực thi cho hook script
    chmod +x /usr/local/bin/update_mosquitto_certs.sh
    #thay đổi cronjob gia hạn mỗi ngày thành gia hạn chứng chỉ sau 2 tháng
    sudo sed -i 's|0 \*/12 \* \* \*|0 0 1 \*/2 \*|' /etc/cron.d/certbot
    #cập nhật cronjob để thực hiện lệnh update cert cho mqtt sau khi gia hạn
    sudo sed -i 's|sleep-on-renew|sleep-on-renew --deploy-hook \"/bin/bash /usr/local/bin/update_mosquitto_certs.sh &\"|' /etc/cron.d/certbot



}

# Hàm cấu hình Mosquitto với self-signed certificate
configure_mosquitto_selfsigned() {
    # Tạo thư mục chứa chứng chỉ
    sudo mkdir -p /etc/mosquitto/certs
    cd /etc/mosquitto/certs
    # Tạo self-signed certificate
   # sudo openssl req -new -x509 -days 365 -nodes -out /etc/mosquitto/certs/mosquitto.crt -keyout /etc/mosquitto/certs/mosquitto.key -subj "/CN=localhost"
    echo "----------- CREATE  Certificate Authority (CA) ---------------"
    sudo openssl req -new -x509 -days 1095 -extensions v3_ca -keyout ca.key -out ca_self_cert.crt
    sudo openssl genrsa -out private_self_cert.key 2048
    sudo openssl req -out mosquitto.csr -key private_self_cert.key -new
    echo "----------- CREATE  Certificate ---------------"
    sudo openssl x509 -req -in mosquitto.csr -CA ca_self_cert.crt -CAkey ca.key -CAcreateserial -out cert_self_cert.crt -days 1095
    sudo chmod 0600 /etc/mosquitto/certs/*
    sudo chown mosquitto: /etc/mosquitto/certs/*
    # Cấu hình Mosquitto với self-signed certificate
    sudo tee /etc/mosquitto/conf.d/ssl.conf > /dev/null <<EOT
listener 8883
cafile /etc/mosquitto/certs/ca_self_cert.crt
certfile /etc/mosquitto/certs/cert_self_cert.crt
keyfile /etc/mosquitto/certs/private_self_cert.key
#require_certificate true
EOT

    sudo systemctl restart mosquitto

     echo "----- Lưu ý: Bạn đang cấu hình MQTT với self-cert. ---------"
     echo "--> Sao chép 'cert_self_cert.crt' tới client sau đó thực thi với đối số: --cafile cert_self_cert.crt --tls-version tlsv1.2 "
}

check_escape() {
  read -rsn1 input
  if [[ $input == $'\e' ]]; then
    return 1
  fi
  return 0
}

hardening_mqtt() {

    echo "------- START CREATE MQTT USER FOR AUTHENT-------------"
    sudo touch /etc/mosquitto/passwd
    chmod 0700 /etc/mosquitto/passwd
    echo "allow_anonymous false" >> /etc/mosquitto/conf.d/ssl.conf
    echo "password_file /etc/mosquitto/passwd" >> /etc/mosquitto/conf.d/ssl.conf
    while true; do
        read -p "Tạo User MQTT:" username

        echo "Nhập password:"
        read -rs password
        echo

        # Tạo user MQTT
        sudo mosquitto_passwd -b /etc/mosquitto/passwd "$username" "$password"
        echo "User $username đã được tạo thành công."

        echo "Nhấn Enter để tiếp tục: (Esc để thoát)"

        # Kiểm tra phím ESC
        check_escape
        if [[ $? -eq 1 ]]; then
            echo "Đã ngừng tạo mới user:"
            break
        fi
    done

}
# Chương trình chính
read -p "Nhập domain bạn muốn cài đặt MQTT server với SSL (để trống hoặc nhập localhost để dùng self-signed certificate): " DOMAIN
echo "----------------------------------------------------------"

server_ip=$(curl -s ifconfig.co)

# Lấy bản ghi A của domain
domain_ip=$(dig +short $DOMAIN)

 # Kiểm tra domain và cấu hình SSL tương ứng
if [[ -z "$DOMAIN" || "$DOMAIN" == "localhost" ]]; then
    echo "Cấu hình MQTT với self-signed certificate"
    install_mosquitto
    configure_mosquitto_selfsigned
else
    echo "Cấu hình MQTT với SSL Let's Encrypt cho domain: $DOMAIN"
    # Kiểm tra nếu domain không có bản ghi A hoặc bản ghi A không trỏ về server_ip
    if [[ -z $domain_ip ]]; then
        echo "Domain $domain không có bản ghi A."
    elif [[ $domain_ip != $server_ip ]]; then
        echo "[DNS error:] Domain $domain chưa trỏ bản ghi A về IP $server_ip."
    else
        echo "Domain $domain đã trỏ bản ghi A về IP $server_ip."
        # Cài đặt Mosquitto
        install_mosquitto
        configure_mosquitto_letsencrypt $DOMAIN
    fi
fi
hardening_mqtt
echo "Hoàn tất cài đặt MQTT server."
