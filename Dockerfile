FROM centos:centos7

MAINTAINER  Luis Camilo <luis.camilo@cleargageinc.com>

ENV VIRTUALENVWRAPPER_PYTHON=/opt/python3.5/bin/python3.5
ENV VERSION=3.0.0-50-gfd61756

# Get system ready
RUN yum -y update && \
    yum clean all && \
    yum -y install epel-release && \
    yum install -y gcc autoconf flex bison libjpeg-turbo-devel  freetype-devel zlib-devel zeromq3-devel gdbm-devel ncurses-devel automake make libtool libffi-devel curl git tmux libxml2-devel libxslt-devel wget openssl-devel gcc-c++ install openssl-devel which libpq-dev postgresql-devel tcping

#Python 3.5.2
RUN cd /tmp && \
    curl -o Python-3.5.2.tar.xz https://www.python.org/ftp/python/3.5.2/Python-3.5.2.tar.xz && \
    tar xvf Python-3.5.2.tar.xz && \
    cd Python-3.5.2/ && \
    ./configure --prefix=/opt/python3.5 && \
    make && \
    make install && \
    export PATH=$PATH:/opt/python3.5/bin && \
    rm -f /usr/bin/python && \
    ln -s /opt/python3.5/bin/python3.5 /usr/bin/python && \
    ln -s /opt/python3.5/bin/pip3 /usr/bin/pip

#pip
RUN pip install --upgrade pip && \
    pip install virtualenv virtualenvwrapper && \
    pip install circus && \
    ln -s /opt/python3.5/bin/virtualenv /usr/bin/virtualenv && \
    ln -s /opt/python3.5/bin/virtualenvwrapper /usr/bin/virtualenvwrapper && \
    ln -s /opt/python3.5/bin/circusd /usr/local/bin/circusd && \
    ln -s /opt/python3.5/bin/gunicorn /usr/local/bin/gunicorn && \
    source /opt/python3.5/bin/virtualenvwrapper.sh && \
    mkvirtualenv -p /opt/python3.5/bin/python3.5 taiga && \
    deactivate

# Install taiga-back
RUN \
  mkdir -p /usr/local/taiga && \
  useradd -d /usr/local/taiga taiga && \
  git clone https://github.com/taigaio/taiga-back.git /usr/local/taiga/taiga-back && \
  mkdir /usr/local/taiga/media /usr/local/taiga/static /usr/local/taiga/logs && \
  cd /usr/local/taiga/taiga-back && \
  git checkout $VERSION && \
  pip install celery==3.0.19 && \
  pip install -r requirements.txt && \
  touch /usr/local/taiga/taiga-back/settings/dockerenv.py && \
  touch /usr/local/taiga/circus.ini

# Cleanup sample data
RUN \
   sed -i 's/^enum34/#enum34/' /usr/local/taiga/taiga-back/requirements.txt && \
   sed -i -e '/sample_data/s/^/#/' /usr/local/taiga/taiga-back/regenerate.sh

# Add Taiga Configuration
ADD ./local.py /usr/local/taiga/taiga-back/settings/local.py

# Configure and Start scripts
ADD ./configure /usr/local/taiga/configure
ADD ./start /usr/local/taiga/start
RUN chmod +x /usr/local/taiga/configure /usr/local/taiga/start

VOLUME /usr/local/taiga/media
VOLUME /usr/local/taiga/static
VOLUME /usr/local/taiga/logs

EXPOSE 8000

CMD ["/usr/local/taiga/start"]