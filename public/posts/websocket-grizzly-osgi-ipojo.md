## Setup

The project uses Grizzly HTTP service bundle version 2.2.18 with WebSocket support and iPOJO framework.

```xml
<dependency>
  <groupId>org.glassfish.grizzly.osgi</groupId>
  <artifactId>grizzly-httpservice-bundle</artifactId>
  <version>2.2.18</version>
</dependency>

<dependency>
  <groupId>org.apache.felix</groupId>
  <artifactId>org.apache.felix.ipojo.annotations</artifactId>
  <version>1.6.4</version>
</dependency>
```

We have to activate the websockets support by settings the following framework properties:

```bash
org.osgi.service.http.port=8080
org.glassfish.grizzly.websocketsSupport=true
```

##  A simple 'echo' WebSocketApplication

The following class implements a simple echo websocket app, such as describe [here](http://www.websocket.org/echo.html).

```java
import org.glassfish.grizzly.websockets.WebSocket;
import org.glassfish.grizzly.websockets.WebSocketApplication;

package org.barjo.websocket.test;

public class MyEchoWebSocketApp extends WebSocketApplication {

  @Override
  public boolean isApplicationRequest(HttpRequestPacket request) {
     return true;
  }

  @Override
  public void onMessage(WebSocket socket,String text) {
    socket.send(text); //Echo
  }
}
```

## The meat

We create a simple iPOJO component that use the grizzly websocket engine in order to register MyEchoWebSocketApp. Since the `WebSocketEngine.getEngine()` is static, we don't need to require the HttpService provided by grizlly. This requirement is only here to couple the WebSocketComp lifecycle with the grizzly lifecycle.

```java
import org.apache.felix.ipojo.annotations.*;
import org.glassfish.grizzly.websockets.WebSocketApplication;
import org.glassfish.grizzly.websockets.WebSocketEngine;

package org.barjo.websocket.test;

@Component(name="WebSocketComp")
@Instantiate
public class WebSocketComp {

    @Requires(optional = true)
    private LogService logger;

    @Requires
    private HttpService http;

    private final WebSocketApplication app;

    public WebSocketComp(BundleContext context){
        app=new MyEchoWebSocketApp();
    }


    /**
     * Start the component, register the app.
     */
    @Validate
    private void start(){
        logger.log(LogService.LOG_INFO,"MyEchoWebSocketApp starting.");
        WebSocketEngine.getEngine().register(app);
    }

    /**
     * Stop the Component, unregister the app.
     */
    @Invalidate
    private void stop(){
        logger.log(LogService.LOG_INFO,"MyEchoWebSocketApp stopping.");
        WebSocketEngine.getEngine().unregister(app);
    }
}
```

## The test

You can now test our simple echo application on http://www.websocket.org/echo.html, with the websocket `ws://localhost:8080`.
