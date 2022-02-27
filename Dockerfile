FROM alpine:3.7
ADD bin/{{.application.name}}.linux /usr/local/bin/{{.application.name}}
ENTRYPOINT ["{{.application.name}}"]