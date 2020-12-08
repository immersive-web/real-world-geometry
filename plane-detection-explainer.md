# Plane detection explainer
## Introduction
This document presents an overview of the plane detection API. The idea is that in order for some Augmented Reality scenarios to work nicely, developers need to know about surfaces present in the user’s environment. Example use cases:
- Placing virtual objects in user’s environment.
- Measuring user’s environment.
- Real-world physics interactions.
It’s possible that access to detected plane information will be useful for occlusion as well, though limitations of current RWG runtimes may limit the effectiveness.

Later sections of this document show how applications can enable plane detection and retrieve information about the planes. More advanced use shows how plane lifetime management could be performed in an application. Please note that this document is not supposed to serve as an API reference - it only shows by example how the API could be used.

## Overview
The API is synchronous and frame-based. If plane detection is enabled in an XRSession, each XRFrame will have a set populated with planes tracked by the session. The advantage of a synchronous API is that we can guarantee that the set of returned planes is valid only during that frame, and this allows the User Agent to change their properties as they get refined by the underlying AR SDKs.

The returned set will contain all planes tracked in the current frame, including planes that may not be currently visible. If the plane object was present in the XRFrame’s set in frame N and is not present in the XRFrame’s set in frame N+1, it means that the tracking of that plane was lost / the plane is no longer present and all properties on the object will throw exceptions if the application attempts to access them. If the same plane is detected both in frame N and in frame N+1, it will be represented by the same XRPlane object, with its attributes / state possibly updated.

The information stored in an XRPlane consists of plane orientation (if known), a convex polygon approximating detected plane, and the pose of the plane’s center that can be retrieved given a reference space. The center’s pose describes a new frame of reference in such a way that the Y axis is a plane’s normal vector, and X & Z axes are right and top vectors, respectively. The polygon vertices are specified in the reference space described by the plane center’s pose. The information retrieved from a plane is valid only during the session’s `requestAnimationFrame` callback, same as the XRFrame object from which it was obtained.

Plane tracking is enabled by creating an XRSession with an appropriate feature descriptor. The feature descriptor that the applications can use to enable the feature is `"plane-detection"`.

## Plane detection - quick start
The below steps assume that you already have created a basic application using the [WebXR Device API](https://immersive-web.github.io/webxr/).

In order to use the plane detection API in the WebXR application, we need to first configure the session:
```javascript
const options = {
  requiredFeatures: [ "plane-detection" ]
};

let xrSession = await navigator.xr.requestSession("immersive-ar", options);
```

Subsequently, when the scheduled `requestAnimationFrame()` callback fires, the received XRFrame will now contain plane information in its `detectedPlanes` attribute:
```javascript
let xrReferenceSpace = ...; // XRReferenceSpace retrieved from successful
                            // call to xrSession.requestReferenceSpace().
 
// `requestAnimationFrame` callback:
function onXRFrame(timestamp, frame) {
 let detectedPlanes = frame.detectedPlanes;
 detectedPlanes.forEach(plane => {
   let planePose = frame.getPose(plane.planeSpace, xrReferenceSpace);
   let planeVertices = plane.polygon; // plane.polygon is an array of objects
                                      // containing x,y,z coordinates
   
   // ...draw plane_vertices relative to plane_pose...
 });
 
 frame.session.requestAnimationFrame(onXRFrame);
}
```

## Plane detection - a bit more advanced use
In order to keep track of which planes have been added / removed, it’s possible to store the XRPlane objects and compare them against the set received in the latest frame:

```javascript
let planes = Set();
 
function onXRFrame(timestamp, frame) {
  let detectedPlanes = frame.detectedPlanes;

  planes.forEach(plane => {
    if(!detectedPlanes.has(plane)) {
      // Handle removed plane - `plane` was present in previous frame but is no longer tracked.
    }
  });

  detectedPlanes.forEach(plane => {
    if (planes.has(plane)) {
      if(plane.lastChangedTime == timestamp) {
        // Handle previously seen plane that was updated in current frame.
      } else {
        // Handle previously seen plane that was not updated in current frame.
        // Depending on the application, this could be a no-op.
      }
    } else {
      // Handle new plane.
    }
  });
 
  planes = detectedPlanes;
 
  frame.session.requestAnimationFrame(onXRFrame);
}
```

As shown above, the application can check whether a plane object was updated in current frame by comparing `plane.lastChangedTime` with the `timestamp` passed in to `requestAnimationFrame()` callback. Note that a plane is only treated as updated when some of its attributes have changed. This means that a plane whose `planeSpace` has a different pose relative to some other space will *not* be considered as updated, as the pose is a derived property of a pair of spaces, not the plane object itself.

## Subsumed planes
It is possible that as the understanding of the user’s environment becomes more refined, some planes will be merged into other planes. In the model above, this situation will translate into the removal of a subsumed plane & adjustment of the properties of the subsuming plane.

## Key points
Some of the important takeaways that might not be immediately apparent from the above presented code snippets are as follows:
- The entire API surface is synchronous.
- Plane attributes are only well-defined during `XRSession.requestAnimationFrame()` callback.
- Strictly equal plane objects represent the same plane.
- If a plane was detected in frame N and is still being detected in frame N+1, it will be represented by exactly the same object in `detectedPlanes` set, potentially with updated attributes.
- If a plane was detected in frame N and is no longer being detected in frame N+1, it will not be present in `detectedPlanes` set. Although an application might still contain references to its plane object, any access to its properties will result in an exception.
- If the application needs to access plane data information from previous frames, it has to copy the properties of the planes it’s interested in.

## Synchronous hit-test
Exposing planes to the application also allows the application to implement custom, synchronous hit-test against those planes. Potential downside of this approach is the lack of access to the same data that the underlying AR frameworks are using to perform hit-test - this can result in lower quality of hit-test results when they are computed purely in JavaScript.

## Current limitations
During a session that has enabled plane detection, the information about planes gets refined over time. This poses challenges to the developers as they cannot assume that the plane’s polygon or pose won’t change. Implications of plane information changing are that positioning objects relative to the plane might require adjusting said objects’ positions. One possible solution to this problem would be an introduction of / integrating anchors with plane detection.
