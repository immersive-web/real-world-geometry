# Planes - informing about removal

## Introduction
This document presents & discusses ways of notifying web applications about loss of tracking for previously detected planes, with the end goal of deciding on the API shape that should be implemented. Plane detection is described in more detail in the [explainer](https://github.com/immersive-web/real-world-geometry/blob/master/plane-detection-explainer.md). As shown in [“a bit more advanced use”](https://github.com/immersive-web/real-world-geometry/blob/master/plane-detection-explainer.md#plane-detection---a-bit-more-advanced-use) section, currently there is no built in way for the application to know which of the planes that have previously been detected are no longer being tracked. The applications that are interested in this information (for example for cleanup purposes) are forced to maintain their own set of planes detected in previous frame and compare its contents with the planes detected in current frame - old planes that have not been detected in the current frame are considered removed.

There are multiple possible ways of addressing this problem:
1. Event-based approach.
2. Promise-based approach.
3. Attribute-based approach.

If needed, all of the approaches described below can be extended to inform about plane additions and modifications.

## Event-based approach
Application could be informed of the removal / tracking loss of a plane object by registering an event handler for `onremoved` event (name is not final). In current design of plane detection feature, event handler could reasonably be exposed on either of the 2 interfaces:

- On XRPlane:

```webidl
partial interface XRPlane {
 // Invoked when a plane is no longer being tracked.
 attribute EventHandler onremoved;
}
```

Since the registration for this event must happen for each plane in whose removal the app is interested, the event handler could simply create a closure that captures the plane object:

```javascript
let plane = ...; // Plane obtained from XRFrame's XRWorldInformation.
plane.addEventListener('onremoved', (event) => {
   console.log("Plane removed.", plane);
});
```

- On XRWorldInformation:

```webidl
partial interface XRWorldInformation {
 // Invoked when a plane is no longer being tracked.
 attribute EventHandler onplaneremoved;
}
```

In this case, since the event handler registration happens for entire collection of planes, the plane object that was removed will have to be passed to the registered event listener through the event. Alternatively, the event handler can be renamed to `onplanesremoved` and receive a batch of planes that were removed in the current frame.

### Discussion
With event-based approach, user agent needs to guarantee that all plane removal events are invoked prior to invocation of request animation frame callback for the frame in which the planes are no longer present. This means that once user agent has all the information needed to invoke application’s request animation frame callback, it must first notify the application about plane removals (see [Timings](#timings), duration number 2.). Plane objects that are being removed will have their properties inaccessible or undefined (with the exception of application-added properties) during the execution of event listener callbacks. If the application wants to act on the data during request animation frame callback, it will have to use a custom mechanism of doing so (e.g. by adding removed planes to a list that’s also accessible from request animation frame callback).

## Promise-based approach
This approach is similar to the event-based approach. The difference is that application could be notified about plane removal by attaching a continuation to the promise returned by XRPlane object:

```webidl
partial interface XRPlane {
 // Resolved when a plane is no longer being tracked.
 attribute Promise removed;
}
```

The usage of the promise is as follows:

```javascript
let plane = ...; // Plane obtained from XRFrame's XRWorldInformation.
plane.removed.then(() => {
   console.log("Plane removed.", plane);
});
```

The application will likely attach a continuation to the promise every time a new plane gets detected.

### Discussion
Similarly to event-based approach, the user agent must guarantee that the promise gets resolved prior to request animation frame callback (see [Timings](#timings), duration number 2.). The plane attributes will not be accessible from the continuation. If the application wants to act on the data during request animation frame callback, it will have to use a custom mechanism of doing so (e.g. by adding removed planes to a list that’s also accessible from request animation frame callback).

It’s worth noting that unlike in event-based approach, adding a promise to `XRWorldInformation` interface is *not* proposed here. Having a promise on `XRWorldInformation` would be more problematic as the application would have to keep re-attaching a continuation to the promise every time previous promise got resolved - User Agent would have to guarantee that just prior to resolving previous promise, `XRWorldInformation.planesremoved` will return different promise object than the one about to be resolved. 

## Attribute-based approach
In this approach, the `XRWorldInformation` interface will be extended with attributes that convey information about the planes that used to be present in previous frame but are no longer present in current frame.

```webidl
interface XRPlaneSet {
  readonly setlike<XRPlane>;
}

partial interface XRWorldInformation {
 // (existing attribute) Set with planes detected in current frame.
 readonly attribute XRPlaneSet? detectedPlanes;
 // (new attribute) Set with planes that were detected in previous frame
 // but are no longer detected in current frame.
 readonly attribute XRPlaneSet? removedPlanes;
}
```

This approach is mentioned in github issue [#4](https://github.com/immersive-web/real-world-geometry/issues/4) as “difference list”.

### Discussion
Attribute-based approach is simplest for the web application to deal with, and is consistent with overall API shape as it delivers all frame-related data to the application in the request animation frame callback through `XRFrame` instance. It is sufficient to iterate over list of planes at the beginning of request animation frame callback and perform any cleanup necessary due to planes no longer being detected. The attributes of planes present in `removedPlanes` array are not accessible.

It’s worth noting that if we decide to also add `addedPlanes` and `modifiedPlanes`, some of the data can only be acted upon in request animation frame callback, which makes this approach even more suitable.

## Timings
Above approaches are making guarantees to the app developers about when will the event handlers fire / when will the promises resolve or get rejected, and when can the plane attributes be queried by the application. Below image serves to clarify the possible timings.

![image with possible durations for callbacks](https://github.com/immersive-web/real-world-geometry/raw/master/img/timings-v3.jpg)

Frame N is the frame where a hypothetical plane still exists. Frame N+1 is the frame in which that plane is no longer present.

The vertical line represents the first moment where all data required to invoke application’s request animation frame callback is available to the user agent. The exact moment is implementation-dependent and might not be a single well-defined point in time - for example, there might exist an user-agent implementation where plane-related information is known earlier than viewer’s pose, AR camera image, etc. 

Description of the durations presented above:
1. Duration after request animation frame callback but prior to all data related to frame N+1 being received by the User Agent from AR system.
2. Duration after request animation frame callback and after entire all data related to frame N+1 is received by the User Agent from AR system.
3. Duration after request animation frame callback for frame N but prior to request animation frame callback for frame N+1.
4. Duration of request animation frame callback for frame N.
5. Duration of request animation frame callback for frame N+1.

## Links
- https://github.com/immersive-web/real-world-geometry/blob/master/plane-detection-explainer.md
- https://github.com/immersive-web/real-world-geometry/blob/master/plane-detection-explainer.md#plane-detection---a-bit-more-advanced-use
- https://github.com/immersive-web/real-world-geometry/issues/4
