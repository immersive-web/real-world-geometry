# Security and Privacy Questionnaire

This document answers the [W3C TAG's Security and Privacy
Questionnaire](https://w3ctag.github.io/security-questionnaire/) for the
WebXR Plane Detection Module.

01. What information might this feature expose to Web sites or other parties,
    and for what purposes is that exposure necessary?

The WebXR's plane detection feature exposes information about flat surfaces
detected in users' environments. This information allows WebXR-powered apps to
provide more immersive experience to their user, for example by computing how
virtual objects interact with real world around the users.

02. Do features in your specification expose the minimum amount of information
    necessary to enable their intended uses?

Yes. Plane detection feature leverages the capabilities of the underlying XR
systems to surface only the information about planes detected in the environment
around the user. Notably, the camera image (that could be used to attempt to
compute similar information in JavaScript) is not exposed to the application.

03. How do the features in your specification deal with personal information,
    personally-identifiable information (PII), or information derived from
    them?

The specification does not directly expose personal information. The users'
environment could be used to attempt to infer information about the users
(for example, if planes representing a desk, monitor and floor are detected,
they could potentially be used to approximate the users' height). The specification
allows the user agents to implement the feature in a more privacy-preserving way,
for example by reducing the quality / level of detail of the returned data.
Quantization of plane poses is also possible, but is not mandated.

04. How do the features in your specification deal with sensitive information?

The feature can only be enabled during XR session creation if the WebXR-powered
application asks for it. The user agents have to ask the user for consent prior
to enabling the feature on a newly created session - this mechanism a part of the
core [WebXR](https://immersive-web.github.io/webxr/) specification.

05. Do the features in your specification introduce new state for an origin
    that persists across browsing sessions?

No.

06. Do the features in your specification expose information about the
    underlying platform to origins?

Not directly - if the feature is not enabled on a session, the application could try
to infer whether the user rejected it, or if the user attempted to create an XR session
on a platform that does not support the feature. The core WebXR spec does not directly
expose this information, but it could potentially be computed based on how quickly
the session creation promise got resolved.

07. Do features in this specification allow an origin access to sensors on a user’s
    device?

Not directly. The underlying XR system will most likely leverage sensors and camera
in order to provide the plane detection capabilities.

08. What data do the features in this specification expose to an origin?  Please
    also document what data is identical to data exposed by other features, in the
    same or different contexts.

This specification exposes data about flat surfaces detected in users' environment.
It consists of the pose (position and orientation) of each detected plane, and convex
polygon representing approximate shape of the detected plane. Both the pose and the
planes' polygon may evolve over time, in response to the underlying XR system's
evolving knowledge about users' environment.

09. Do feautres in this specification enable new script execution/loading
    mechanisms?

No.

10. Do features in this specification allow an origin to access other devices?

No.

11. Do features in this specification allow an origin some measure of control over
    a user agent's native UI?

No.

12. What temporary identifiers do the feautures in this specification create or
    expose to the web?

None directly. The planes detected in users' environment can potentially be used
to compute some kind of rough description of the users' environment. This could
potentially be used as a spatial identifier, which could also be used to identify
the user in case the feature was used in a location that is normally only accessible
only to that user (e.g. at home).

13. How does this specification distinguish between behavior in first-party and
    third-party contexts?

It is an extension to WebXR which is by default blocked for third-party contexts
and can be controlled via a Feature Policy flag.

14. How do the features in this specification work in the context of a browser’s
    Private Browsing or Incognito mode?

The specification does not mandate a different behaviour.

15. Does this specification have both "Security Considerations" and "Privacy
    Considerations" sections?

[Yes](https://immersive-web.github.io/real-world-geometry/plane-detection.html#privacy-security).

16. Do features in your specification enable origins to downgrade default
    security protections?

No.

17. What should this questionnaire have asked?

N/A.
