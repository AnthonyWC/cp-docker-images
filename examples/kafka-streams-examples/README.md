# Confluent's Kafka Streams Examples

----
**Table of Contents**

* [Overview](#overview)
* [Running the Kafka Music demo application](#running-kafka-music-demo-application)
* [Running further Confluent demo applications](#running-further-demo-applications)
* [Appendix](#appendix)
    * [Inspecting the input topics](#inspecting-input-topics)
----


<a name="overview"></a>
# Overview

This docker-compose project launches:

- Confluent's [Kafka Music demo application](https://github.com/confluentinc/examples/blob/3.2.x/kafka-streams/src/main/java/io/confluent/examples/streams/interactivequeries/kafkamusic/KafkaMusicExample.java)
  for the Kafka Streams API.  This demo demonstrates how to build of a simple music charts application.  It uses Kafka's
  [Interactive Queries](http://docs.confluent.io/current/streams/developer-guide.html#interactive-queries) feature to
  expose its latest processing results (e.g. latest Top 5 songs) via a REST API.  Its input data is in Avro format,
  hence the use of Confluent Schema Registry (see below).
- a single-node Apache Kafka cluster with a single-node ZooKeeper ensemble
- a [Confluent Schema Registry](https://github.com/confluentinc/schema-registry) instance


<a name="running-kafka-music-demo-application"></a>
# Running the Kafka Music demo application

If you just want to sit back and see what we will be doing in the subsequent sections, take a look at the following
recording:

<a href="https://asciinema.org/a/2ucvl5azwi289s1wxwjlf3c5b">
  <img src="https://asciinema.org/a/2ucvl5azwi289s1wxwjlf3c5b.png" width="400" alt="Running Confluent's Kafka Music demo application (Kafka Streams API)."/>
</a><br />
<strong>Screencast: Running Confluent's Kafka Music demo application (Kafka Streams API).</strong><br />
<br />

> **Mac and Windows users only: start Docker Machine first**
>
> If you haven't done so, create a VM with 6GB of memory as your Docker Machine and name it `confluent`:
>
>     $ docker-machine create --driver virtualbox --virtualbox-memory 6000 confluent
>
> Now configure your terminal to attach it to the new Docker Machine:
>
>     $ eval $(docker-machine env confluent)

Launch the docker-compose project, i.e. launch all the configured services and their containers.
The Kafka Music application is started automatically by its container.

```bash
$ docker-compose up -d
```

Create the input topics of the Kafka Music application:

```bash
# Create the input topic "play-events"
$ docker-compose exec kafka kafka-topics \
    --create --topic play-events \
    --zookeeper localhost:32181 --partitions 4 --replication-factor 1

# Create the input topic "song-feed"
$ docker-compose exec kafka kafka-topics \
    --create --topic song-feed \
    --zookeeper localhost:32181 --partitions 4 --replication-factor 1
```

**Workaround until [PR#2815](https://github.com/apache/kafka/pull/2815) is available:**
Restart the Kafka Music application to make it aware of the newly created topics.

```bash
$ docker-compose restart kafka-streams-examples
```

At this point the application is up and running.  Let's start `KafkaMusicExampleDriver`, which continuously generates
some input data for the application to process:

```bash
# Write some input data to the application's input topics.
# This command will continue to run and generate input data
# until it is terminated with `Ctrl-C`.  Keep it running for now!
$ docker-compose exec kafka-streams-examples \
    java -cp /app/streams-examples-3.2.0-standalone.jar \
    io.confluent.examples.streams.interactivequeries.kafkamusic.KafkaMusicExampleDriver \
    localhost:29092 http://localhost:8081
```

Now we can use our web browser or a CLI tool such as `curl` to interactively query the latest processing results of the
Kafka Music application.

**List all running application instances of the Kafka Music application:**

```bash
# Mac and Windows users
$ curl -sXGET http://`docker-machine ip confluent`:7070/kafka-music/instances

# Linux users
$ curl -sXGET http://localhost:7070/kafka-music/instances

# You should see output similar to following, though here
# the output is pretty-printed so that it's easier to read:
[
  {
    "host": "localhost",
    "port": 7070,
    "storeNames": [
      "all-songs",
      "song-play-count",
      "top-five-songs",
      "top-five-songs-by-genre"
    ]
  }
]
```

**Get the latest Top 5 songs across all music genres:**

```bash
# Mac and Windows users
$ curl -sXGET http://`docker-machine ip confluent`:7070/kafka-music/charts/top-five

# Linux users
$ curl -sXGET http://localhost:7070/kafka-music/charts/top-five

# You should see output similar to following, though here
# the output is pretty-printed so that it's easier to read:
[
  {
    "artist": "N.W.A",
    "album": "Straight Outta Compton",
    "name": "Gangsta Gangsta",
    "plays": 298
  },
  {
    "artist": "Anti-Nowhere League",
    "album": "We Are the League",
    "name": "Animal",
    "plays": 293
  },

  ... rest omitted...
]
```

The REST API exposed by the
[Kafka Music application](https://github.com/confluentinc/examples/blob/3.2.x/kafka-streams/src/main/java/io/confluent/examples/streams/interactivequeries/kafkamusic/KafkaMusicExample.java)
contains supports further operations.  See the
[top-level instructions in its source code](https://github.com/confluentinc/examples/blob/3.2.x/kafka-streams/src/main/java/io/confluent/examples/streams/interactivequeries/kafkamusic/KafkaMusicExample.java)
for further information.

Once you're done playing around you can stop this example:

1. Stop the `docker-compose exec` command for `KafkaMusicExampleDriver` (via `Ctrl-C`) that is generating the input
   data.
2. Stop all the services and containers with `docker-compose down`.

That's it.  We hope you enjoyed this demo!


<a name="running-further-demo-applications"></a>
# Running further Confluent demo applications

The container named `kafka-streams-examples`, which runs the Kafka Music demo application, actually contains all of
Confluent's [Kafka Streams demo applications](https://github.com/confluentinc/examples).  The demo applications are
packaged in the fat jar at `/app/streams-examples-3.2.0-standalone.jar` inside this container.  This means you can
easily run any of these applications from inside the container via a command similar to:

```bash
# Example: Launch the WordCount demo application
$ docker-compose exec kafka-streams-examples \
        java -cp /app/streams-examples-3.2.0-standalone.jar \
        io.confluent.examples.streams.WordCountLambdaExample \
        localhost:29092
```

Note that you must follow the full instructions of each demo application (see its respective source code at
https://github.com/confluentinc/examples).  These instructions include, for example, the creation of the application's
input and output topics.  Also, each demo application supports CLI arguments.  Typically, the first CLI argument is
the `bootstrap.servers` parameter and the second argument, if any, is the `schema.registry.url` setting.

Available endpoints **from within the containers** of this docker-compose project:

| Endpoint                  | Parameter             | Value                   |
|---------------------------|-----------------------|-------------------------|
| Kafka Cluster             | `bootstrap.servers`   | `localhost:29092`       |
| Confluent Schema Registry | `schema.registry.url` | `http://localhost:8081` |
| ZooKeeper ensemble        | `zookeeper.connect`   | `localhost:32181`       |


<a name="appendix"></a>
# Appendix


<a name="inspecting-input-topics"></a>
## Inspecting the input topics

> **Mac and Window users:**
> Ensure that your your terminal is configured to attach to the `confluent` Docker Machine:
>
>     $ eval $(docker-machine env confluent)

```bash
$ docker-compose exec schema-registry \
    kafka-avro-console-consumer \
        --zookeeper localhost:32181 \
        --topic play-events --from-beginning

# You should see output similar to:
{"song_id":11,"duration":60000}
{"song_id":10,"duration":60000}
{"song_id":12,"duration":60000}
{"song_id":2,"duration":60000}
{"song_id":1,"duration":60000}
```

```bash
$ docker-compose exec schema-registry \
    kafka-avro-console-consumer \
        --zookeeper localhost:32181 \
        --topic song-feed --from-beginning

# You should see output similar to:
{"id":1,"album":"Fresh Fruit For Rotting Vegetables","artist":"Dead Kennedys","name":"Chemical Warfare","genre":"Punk"}
{"id":2,"album":"We Are the League","artist":"Anti-Nowhere League","name":"Animal","genre":"Punk"}
{"id":3,"album":"Live In A Dive","artist":"Subhumans","name":"All Gone Dead","genre":"Punk"}
{"id":4,"album":"PSI","artist":"Wheres The Pope?","name":"Fear Of God","genre":"Punk"}
```