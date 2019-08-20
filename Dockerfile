FROM raspbian/stretch AS build

WORKDIR /root
RUN apt-get update && apt-get install -y --no-install-recommends git bash make g++ \
  && git clone https://github.com/mysensors/MySensors.git --branch development 
WORKDIR MySensors
RUN echo "##### Building version: $(cat library.properties | grep version | cut -d= -f2)-$(git describe --tags)"
RUN LDFLAGS="-static" ./configure --my-transport=rfm69 --my-rfm69-frequency=433 --my-is-rfm69hw --my-gateway=mqtt --my-controller-ip-address=<ip> --my-mqtt-user=<user> --my-mqtt-password=<password> --my-mqtt-publish-topic-prefix=mysensors-out --my-mqtt-subscribe-topic-prefix=mysensors-in  --my-leds-err-pin=12 --my-leds-rx-pin=16 --my-leds-tx-pin=18 --my-config-file=/data/mysensors.conf --spi-driver=BCM --soc=BCM2836 --cpu-flags="-mcpu=cortex-a53 -mfloat-abi=hard -mfpu=neon-fp-armv8 -mneon-for-64bits -mtune=cortex-a53" \
  && make

FROM hypriot/rpi-alpine-scratch
RUN mkdir /data
WORKDIR /root
COPY --from=build /root/MySensors/bin/mysgw .

EXPOSE 5003
ENTRYPOINT ["./mysgw"]
