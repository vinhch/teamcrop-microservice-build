FROM voduytuan/docker-nginx-php:latest

RUN apt-get update 
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y python-setuptools collectd python-pip

# Install supervisord
RUN easy_install supervisor

# install envtpl for replace
RUN pip install envtpl


# Copy source directory to default nginx root directory
ADD www             /var/www

# Copy startup script for getting environment information such as config...
ADD startup.sh      /var/startup.sh
RUN chmod +x /var/startup.sh


# Add configuration files

# collectd config
ADD collectd-config.conf.tpl /etc/collectd/configs/collectd-config.conf.tpl

# supervisord config
ADD supervisord.conf /etc/supervisord.conf

# create log directory for supervisord
RUN mkdir /var/log/supervisor/

CMD [ "/var/startup.sh" ]
