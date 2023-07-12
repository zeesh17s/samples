#!/bin/bash
set -a

. ${PWD}/configs

SERVER0="k3d-$CLUSTERNAME-server-0"   # name auto generated by k3d.

TEMPLATEDIR="${PWD}/templ"
PRELIMDIR="${PWD}/prelim"
DEPLOY="${PRELIMDIR}/deploy.yaml"
 
[ ! -d $DATADIR ] && { echo "Directory to store pihole data is not found. $DATADIR "; exit 3; }  \
                  || echo "Mounting data at: $DATADIR "

[ -f $DEPLOY ]  && rm $DEPLOY
[ -f $PRELIMDIR/metallb-config.yaml ] && rm $PRELIMDIR/metallb-config.yaml


create_br() {
       echo "creating network $DOCKERBR";
       docker network create -d macvlan -o parent=$PARENTINF  \
       --subnet=$SUBNET \
       --gateway=$GATEWAY \
       --ip-range=$IPRANGE \
       ${DOCKERBR}      
          
      [ $? -eq 0 ] && echo "Network created" ||  { echo "Failed creating network $DOCKERBR"; exit; } 
}

if [ ! $(docker network ls -f "Name=${DOCKERBR}" -q) ]; then
       echo "Docker network $DOCKERBR not found. creating.."
       create_br
else 
      echo -e "$DOCKERBR already exists."
      while true; do
          read -p "Do you want to recreate it? [Y|N] " resp
          case $resp in
            [Yy]* ) docker network rm $DOCKERBR;
                    create_br;
                    break;;
            [Nn]* ) echo "Using existing one"; break;;
                * ) echo "Please select valid option."; ;;
          esac
      done 
fi

NODE_AFFINITY=$SERVER0
PASSWORD_ENCODED=$(cat <(echo -n $WEB_PASSWORD | base64 ) )

 # Generate metallb-config.yaml
 sed "s/{{IP_START_RANGE}}/$IP_START_RANGE/g; s/{{IP_END_RANGE}}/$IP_END_RANGE/g" ${TEMPLATEDIR}/metallb-config.yaml \
        > ${PRELIMDIR}/metallb-config.yaml

 find  $TEMPLATEDIR/* ! -name "metallb*"  -type f  -printf "%f\n" | sort | xargs   -I{} \
       sh -c  'sed -e "s/{{NODE_AFFINITY}}/$NODE_AFFINITY/g; 
                       s#{{TIMEZONE}}#$TIMEZONE#g; 
                       s/{{IP_PIHOLE}}/$IP_PIHOLE/g; 
                       s/{{WEBPASSWORD}}/$PASSWORD_ENCODED/g;  " \
                       $TEMPLATEDIR/"$1" >> "$DEPLOY";  echo "\n---\n" >> "$DEPLOY";' -- {}

# create cluster
k3d cluster create --config create-cluster.yaml

# print nodes ip addresse
printf "Server-0 ip address:  %s\n\n"  \
 $(sh -c "docker inspect $SERVER0 --format '{{\$network:= index .NetworkSettings.Networks \"$DOCKERBR\"}}{{ \$network.IPAddress}}'")


cat <<EOF  >&1
for host to container communication, a bridge can be created as:
  ip link add host-cntr link eth0 type macvlan mode bridge
  ip addr add 192.168.1.X/X dev host-cntr
  ip l set host-cntr up
  ip route add 192.168.1.X/X dev host-cntr
 
add to /etc/hosts :
  ${KUBE_API_IP}   ${SERVER0}

WebURL:  http://${IP_PIHOLE}/admin  
EOF

set +a