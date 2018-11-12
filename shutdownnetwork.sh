echo "shutdown fabric-network"
echo
docker-compose -f artifacts/docker-compose.yaml down
echo

echo "docker rm -f $(docker ps -aq)"
echo
docker rm -f $(docker ps -aq)
echo

echo "docker rmi -f $(docker images | grep dev | awk '{print $3}')"
echo
docker rmi -f $(docker images | grep dev | awk '{print $3}')
echo

echo "Delete current dir org-kv"
echo
rm -rf fabric-client-kv-org[1-2]
echo

echo "Delete tmp dir org-kv"
echo
rm -rf /tmp/fabric-client-kv-org[1-2]
echo

echo "shutdown and clear OK"

