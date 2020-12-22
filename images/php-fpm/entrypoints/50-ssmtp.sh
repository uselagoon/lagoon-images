#!/bin/sh


if [ ${SSMTP_REWRITEDOMAIN+x} ]; then
  echo -e "\nrewriteDomain=${SSMTP_REWRITEDOMAIN}" >> /etc/ssmtp/ssmtp.conf
fi
if [ ${SSMTP_AUTHUSER+x} ]; then
  echo -e "\nAuthUser=${SSMTP_AUTHUSER}" >> /etc/ssmtp/ssmtp.conf
fi
if [ ${SSMTP_AUTHPASS+x} ]; then
  echo -e "\nAuthPass=${SSMTP_AUTHPASS}" >> /etc/ssmtp/ssmtp.conf
fi
if [ ${SSMTP_USETLS+x} ]; then
  echo -e "\nUseTLS=${SSMTP_USETLS}" >> /etc/ssmtp/ssmtp.conf
fi
if [ ${SSMTP_USESTARTTLS+x} ]; then
  echo -e "\nUseSTARTTLS=${SSMTP_USESTARTTLS}" >> /etc/ssmtp/ssmtp.conf
fi

if [ ${SSMTP_MAILHUB+x} ]; then
  echo -e "\nmailhub=${SSMTP_MAILHUB}" >> /etc/ssmtp/ssmtp.conf
# check if we find a mailhog on 172.17.0.1:1025
elif nc -z -w 1 172.17.0.1 1025 &> /dev/null; then
  echo -e "\nmailhub=172.17.0.1:1025" >> /etc/ssmtp/ssmtp.conf
  return
# Fallback: check if on Lagoon then assume mxout.lagoon.svc can do smtp TLS
elif [[ ! -z ${LAGOON_PROJECT} ]]; then
  echo -e "UseTLS=Yes\nmailhub=mxout.lagoon.svc:465" >> /etc/ssmtp/ssmtp.conf
  return
fi
