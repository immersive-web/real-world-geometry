# Plane detection explainer
## Introduction
This document presents an overview of the plane detection API. The idea is that in order for some Augmented Reality scenarios to work nicely, developers need to know about surfaces present in the user’s environment. Example use cases:
- Placing virtual objects in user’s environment. This use case is partially addressed by WebXR's hit-test API. Plane detection API extends the amount of information returned to the sites, allowing them to not only find where the rays would intersect with the real world, but also compute approximate area of detected surfaces.
- Measuring user’s environment. The sites could then leverage that knowledge and procedurally generate game arenas or otherwise adapt to the system expanding its knowledge of the environment.
- Real-world physics interactions. The sites could compute how the virtual objects should behave when colliding with user's environment. Other physical interactions are also possible (e.g. computing echo effects based on planes detected around the user).
It’s possible that access to detected plane information will be useful for occlusion as well, though limitations of current RWG runtimes may limit the effectiveness.

Later sections of this document show how applications can enable plane detection and retrieve information about the planes. More advanced use shows how plane lifetime management could be performed in an application. Please note that this document is not supposed to serve as an API reference - it only shows by example how the API could be used.

## Overview
The API is synchronous and frame-based. If plane detection is enabled in an XRSession, each XRFrame will have a set populated with planes tracked by the session. The advantage of a synchronous API is that we can guarantee that the set of returned planes is valid only during that frame, and this allows the User Agent to change their properties as they get refined by the underlying AR SDKs.

The returned set will contain all planes tracked in the current frame. That may or may not include planes that are currently not visible to the device. If the plane object was present in the XRFrame’s set in frame N and is not present in the XRFrame’s set in frame N+1, it means that the tracking of that plane was lost / the plane is no longer present and all properties on the object will throw exceptions if the application attempts to access them. If the same plane is detected both in frame N and in frame N+1, it will be represented by the same XRPlane object, with its attributes / state possibly updated.

The information stored in an XRPlane consists of plane orientation (if known), a convex polygon approximating detected plane, and the pose of the plane’s center that can be retrieved given a reference space. The center’s pose describes a new frame of reference in such a way that the Y axis is a plane’s normal vector, and X & Z axes are right and top vectors, respectively. The polygon vertices are specified in the reference space described by the plane center’s pose, and are returned in the form of a loop of points at the edges of the polygon. The information retrieved from a plane is valid and specified only when the XRFrame is `active`.

Plane tracking is enabled by creating an XRSession with an appropriate feature descriptor. The feature descriptor that the applications can use to enable the feature is `"plane-detection"`.

## Plane detection - quick start
The below steps assume that you already have created a basic application using the [WebXR Device API](https://immersive-web.github.io/webxr/).

In order to use the plane detection API in the WebXR application, we need to first configure the session:
```javascript
const options = {
  requiredFeatures: [ "plane-detection" ]
};

const xrSession = await navigator.xr.requestSession("immersive-ar", options);
```

Subsequently, when the scheduled `requestAnimationFrame()` callback fires, the received XRFrame will now contain plane information in its `detectedPlanes` attribute:
```javascript
const xrReferenceSpace = ...; // XRReferenceSpace retrieved from successful
                              // call to xrSession.requestReferenceSpace().
 
// `requestAnimationFrame` callback:
function onXRFrame(timestamp, frame) {
 const detectedPlanes = frame.detectedPlanes;
 detectedPlanes.forEach(plane => {
   const planePose = frame.getPose(plane.planeSpace, xrReferenceSpace);
   const planeVertices = plane.polygon; // plane.polygon is an array of objects
                                        // containing x,y,z coordinates
   
   // ... draw plane_vertices relative to plane_pose ...
 });
 
 frame.session.requestAnimationFrame(onXRFrame);
}
```

## Plane detection - more advanced use
In order to keep track of which planes have been added / removed, it’s possible to store the XRPlane objects and compare them against the set received in the latest frame:

```javascript
const planes = Map();
 
function onXRFrame(timestamp, frame) {
  const detectedPlanes = frame.detectedPlanes;

  // First, let's check if any of the planes we know about is no longer tracked:
  for (const [plane, timestamp] of planes) {
    if(!detectedPlanes.has(plane)) {
      // Handle removed plane - `plane` was present in previous frame,
      // but is no longer tracked.

      // We know the plane no longer exists, no need to maintain it in the map:
      planes.delete(plane);
    }
  }

  // Then, let's handle all the planes that are still tracked.
  // This consists both of tracked planes that we have previously seen, and new planes.
  // The planes that we've previuosly seen may have been updated.
  detectedPlanes.forEach(plane => {
    if (planes.has(plane)) {
      if(plane.lastChangedTime != planes.get(plane)) {
        // Handle previously seen plane that was updated in current frame.
        // What this means that one of the plane's properties is different than
        // it used to be - most likely, the polygon has changed.

        // Update the lastChangeTime:
        planes.set(plane, plane.lastChangedTime);
      } else {
        // Handle previously seen plane that was not updated in current frame.
        // Depending on the application, this could be a no-op.
        // Note that plane's pose relative to some other space MAY have changed,
        // because a pose can be seen as a property derived from 2 entities (XRSpaces).
      }
    } else {
      // Handle new plane.

      // Update the lastChangeTime:
      planes.set(plane, plane.lastChangedTime);
    }

    // Irrespective of whether the plane is new or old, updated or not, its pose
    // may have changed:
    const planePose = frame.getPose(plane.planeSpace, xrReferenceSpace);
  });

  frame.session.requestAnimationFrame(onXRFrame);
}
```

As shown above, the application can check whether a plane object was updated in current frame by comparing `plane.lastChangedTime` with the `lastChangedTime` from the previous time the plane was accessed. Note that a plane is only treated as updated when some of its attributes have changed. This means that a plane whose `planeSpace` has a different pose relative to some other space will **not** be considered as updated, as the pose is a derived property of a pair of spaces, not the plane object itself.

## Subsumed planes
It is possible that as the understanding of the user’s environment becomes more refined, some planes will be merged into other planes. In the model above, this situation will translate into the removal of a subsumed plane & adjustment of the properties of the subsuming plane.

## Key points
Some of the important takeaways that might not be immediately apparent from the above presented code snippets are as follows:
- The entire API surface is synchronous.
- Plane attributes are only well-defined as long as the frame is `active`.
- Triple-equal plane objects represent the same plane.
- If a plane was detected in frame N and is still being detected in frame N+1, it will be represented by exactly the same object in `detectedPlanes` set, potentially with updated attributes.
- If a plane was detected in frame N and is no longer being detected in frame N+1, it will not be present in `detectedPlanes` set. Although an application might still contain references to its plane object, any access to its properties will result in an exception.
- If the application needs to access plane data information from previous frames, it has to copy the properties of the planes it’s interested in.

## Synchronous hit-test
Exposing planes to the application also allows the application to implement custom, synchronous hit-test against those planes. Potential downside of this approach is the lack of access to the same data that the underlying AR frameworks are using to perform hit-test - this can result in lower quality of hit-test results when they are computed purely in JavaScript.

## Current limitations
During a session that has enabled plane detection, the information about planes gets refined over time. This poses challenges to the developers as they cannot assume that the plane’s polygon or pose won’t change. Implications of plane information changing are that positioning objects relative to the plane might require adjusting said objects’ positions. One possible solution to this problem would be an introduction of / integrating anchors with plane detection.

## Appendix: Discussion on notifying about plane changes

See [Planes - informing about removal](planes-notifying-about-removal.md).

## Appendix: proposed Web IDL

```webidl

enum XRPlaneOrientation {
    "horizontal",
    "vertical"
};

interface XRPlane {
    readonly attribute XRSpace planeSpace;

    readonly attribute FrozenArray<DOMPointReadOnly> polygon;
    readonly attribute XRPlaneOrientation? orientation;
    readonly attribute DOMHighResTimeStamp lastChangedTime;
};

interface XRPlaneSet {
  readonly setlike<XRPlane>;
};

partial interface XRFrame {
  readonly attribute XRPlaneSet detectedPlanes;
};
```
