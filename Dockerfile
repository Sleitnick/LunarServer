FROM debian:latest

WORKDIR /

COPY buildlua.sh /buildlua.sh
RUN chmod +x /buildlua.sh

RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get -y install curl build-essential
RUN /buildlua.sh
