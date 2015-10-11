FROM voduytuan/docker-nginx-php:latest

# Copy source directory to default nginx root directory
ADD www             /var/www

# Copy startup script for getting environment information such as config...
ADD startup.sh      /var/startup.sh

CMD [ "/var/startup.sh" ]
