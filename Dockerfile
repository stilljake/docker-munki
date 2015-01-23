FROM nmcspadden/munki

MAINTAINER Nick McSpadden nmcspadden@gmail.com

ENV PUPPET_VERSION 3.7.3

RUN apt-get update
RUN apt-get install -y wget
RUN apt-get install -y ca-certificates
RUN wget https://apt.puppetlabs.com/puppetlabs-release-wheezy.deb
RUN dpkg -i puppetlabs-release-wheezy.deb
RUN apt-get update
RUN apt-get install -y puppet=$PUPPET_VERSION-1puppetlabs1
ADD csr_attributes.yaml /etc/puppet/csr_attributes.yaml
