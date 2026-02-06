FROM neo4j:latest

COPY neo4j.dump /dumps/neo4j.dump

RUN neo4j-admin database load neo4j --from-path=/dumps --overwrite-destination=true

RUN chown -R neo4j:neo4j /var/lib/neo4j/data

ENV NEO4J_AUTH=neo4j/testpassword
ENV NEO4J_server_default__listen__address=0.0.0.0

EXPOSE 7474 7687
