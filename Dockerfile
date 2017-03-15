FROM openjdk:8-jdk

# Cantaloupe docker starter script

ENV CANTALOUPE_VERSION 3.3

# Update packages and install tools 
RUN apt-get update && apt-get install -y --no-install-recommends \
	wget git gcc g++ unzip make pkg-config

# Install cmake 3.2
WORKDIR /tmp/cmake
RUN wget http://www.cmake.org/files/v3.2/cmake-3.2.2.tar.gz && tar xf cmake-3.2.2.tar.gz && cd cmake-3.2.2 && ./configure && make && make install

# Install imaging tools
RUN apt-get install -y liblcms2-dev  libtiff-dev libpng-dev libz-dev libopenjp2-7

# Download and compile OpenJPEG v2.1.2
WORKDIR /tmp/openjpeg
RUN git clone https://github.com/uclouvain/openjpeg.git ./
RUN git checkout tags/v2.1.2
RUN cmake . && make && make install

# run non priviledged
#RUN groupadd -r www-data && useradd -r -g www-data cantaloupe
#RUN adduser -S cantaloupe
RUN groupadd -f www-data && useradd -d /home -g www-data -s /sbin/false cantaloupe

#
# Cantaloupe
#
WORKDIR /tmp
RUN curl -OL https://github.com/medusa-project/cantaloupe/releases/download/v$CANTALOUPE_VERSION/Cantaloupe-$CANTALOUPE_VERSION.zip \
 && mkdir -p /usr/local/ \
 && cd /usr/local \
 && unzip /tmp/Cantaloupe-$CANTALOUPE_VERSION.zip \
 && ln -s Cantaloupe-$CANTALOUPE_VERSION cantaloupe \
 && rm -rf /tmp/Cantaloupe-$CANTALOUPE_VERSION \
 && rm /tmp/Cantaloupe-$CANTALOUPE_VERSION.zip

# Configuration and log directories
COPY cantaloupe.properties /etc/cantaloupe.properties 
ENV CACHEDIR /var/cache/cantaloupe
RUN mkdir -p /var/log/cantaloupe \
 && mkdir -p $CACHEDIR \
 && chown -R cantaloupe /var/log/cantaloupe \
 && chown -R cantaloupe $CACHEDIR \
 && chown cantaloupe /etc/cantaloupe.properties

# Delegate script and dependencies
ENV GEMSDIR /usr/local
RUN apt-get install -y rubygems
COPY delegates.rb /etc/delegates.rb
# Give access to installed gems and set imagesdir
RUN sed -i "1igemsdir = '$GEMSDIR/gems'\n$:.concat(Dir.entries(gemsdir).select {|entry| File.directory? File.join(gemsdir,entry) and \!(entry =='.' || entry == '..') }.map{|x| File.join(gemsdir, x, 'lib')} )\nIMAGESDIR='$CACHEDIR'" /etc/delegates.rb 
COPY keyfile-pub.pem /home/keyfile-pub.pem
RUN gem install -i $GEMSDIR jwt aws-sdk

EXPOSE 8182

USER cantaloupe 
WORKDIR /home
CMD ["sh", "-c", "java -Dcantaloupe.config=/etc/cantaloupe.properties -Xmx2g -jar /usr/local/cantaloupe/Cantaloupe-$CANTALOUPE_VERSION.war"]

