FROM openjdk:11

RUN sed -i "/jdk.tls.disabledAlgorithms=/ s/=.*/=TLSv1.3, SSLv3, RC4, MD5withRSA, DH keySize < 1024, EC keySize < 224, DES40_CBC, RC4_40, 3DES_EDE_CBC/" $(readlink -f /usr/local/openjdk-11/bin/java | sed "s:bin/java::")/conf/security/java.security

#ADD searchws /opt/searchws
ADD run.sh /opt/run.sh
WORKDIR /opt

RUN chmod +x run.sh
ENTRYPOINT ["./run.sh"]
