<%# XXX Forcefully removing rabbitmq source until next build env update %>
<%# See http://www.traviscistatus.com/incidents/6xtkpm1zglg3 %>
if [[ -f /etc/apt/sources.list.d/rabbitmq-source.list ]] ; then
  sudo rm -f /etc/apt/sources.list.d/rabbitmq-source.list
fi

<%# XXX Forcefully removing neo4j source until we figure out a better way %>
<%# See https://www.traviscistatus.com/incidents/fyskznm7wg2c %>
if [[ -f /etc/apt/sources.list.d/neo4j.list ]] ; then
  sudo rm -f /etc/apt/sources.list.d/neo4j.list
fi
