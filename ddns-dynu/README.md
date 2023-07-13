# Intro

 Script to update ip address for dynamic domain name from [dynu](dynu.com).

It can be run as a usual cron job or in a docker container.

To run in a docker container:


```
 docker run -itd \
--name $CONTAINER \
--env apiKey=<API_KEY> \
--env ddnsname=domainname-here \
--restart=unless-stopped \
$IMAGE
```


